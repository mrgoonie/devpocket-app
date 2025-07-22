# Backend Python Server - K8s Terminal

## 1. Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── deployments.py
│   │   └── websocket.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── k8s_service.py
│   │   ├── websocket_service.py
│   │   └── auth_service.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── deployment.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   ├── database.py
│   │   └── security.py
│   └── middleware/
│       ├── __init__.py
│       └── auth.py
├── requirements.txt
├── Dockerfile
└── docker-compose.yml
```

## 2. Core Dependencies

```txt
# requirements.txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
websockets==12.0
kubernetes==29.0.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
motor==3.3.2  # Async MongoDB driver
pymongo==4.6.1
python-multipart==0.0.6
pydantic==2.5.3
pydantic-settings==2.1.0
aiofiles==23.2.1
python-dotenv==1.0.0
```

## 3. K8s Service Implementation

```python
# app/services/k8s_service.py
from kubernetes import client, config
from kubernetes.client import ApiException
from kubernetes.stream import stream
import asyncio
import uuid
from typing import Dict, Optional, Any
import logging

logger = logging.getLogger(__name__)

class K8sService:
    def __init__(self):
        try:
            # Try to load in-cluster config first
            config.load_incluster_config()
        except:
            # Fall back to kubeconfig file
            config.load_kube_config()
        
        self.v1 = client.CoreV1Api()
        self.apps_v1 = client.AppsV1Api()
    
    async def create_user_environment(self, user_id: str) -> Dict[str, Any]:
        namespace = f"user-{user_id}"
        deployment_name = f"dev-env-{user_id}"
        
        # Create namespace
        await self._create_namespace(namespace)
        
        # Create PVC
        await self._create_pvc(namespace, f"pvc-{deployment_name}")
        
        # Create deployment
        deployment = self._build_deployment_spec(deployment_name, namespace)
        await self._create_deployment(namespace, deployment)
        
        # Create service
        await self._create_service(namespace, deployment_name)
        
        # Wait for pod to be ready
        pod_name = await self._wait_for_pod(namespace, deployment_name)
        
        return {
            "namespace": namespace,
            "deployment_name": deployment_name,
            "pod_name": pod_name,
            "service_url": f"{deployment_name}.{namespace}.svc.cluster.local"
        }
    
    def _build_deployment_spec(self, name: str, namespace: str) -> client.V1Deployment:
        # Container spec
        container = client.V1Container(
            name="dev-container",
            image="ubuntu:22.04",
            command=["/bin/bash"],
            args=["-c", "apt-get update && apt-get install -y curl git vim python3 nodejs && tail -f /dev/null"],
            resources=client.V1ResourceRequirements(
                limits={"cpu": "1000m", "memory": "2Gi"},
                requests={"cpu": "500m", "memory": "1Gi"}
            ),
            volume_mounts=[
                client.V1VolumeMount(
                    name="workspace",
                    mount_path="/workspace"
                )
            ]
        )
        
        # Pod spec
        pod_spec = client.V1PodSpec(
            containers=[container],
            volumes=[
                client.V1Volume(
                    name="workspace",
                    persistent_volume_claim=client.V1PersistentVolumeClaimVolumeSource(
                        claim_name=f"pvc-{name}"
                    )
                )
            ]
        )
        
        # Deployment spec
        return client.V1Deployment(
            api_version="apps/v1",
            kind="Deployment",
            metadata=client.V1ObjectMeta(name=name, namespace=namespace),
            spec=client.V1DeploymentSpec(
                replicas=1,
                selector=client.V1LabelSelector(
                    match_labels={"app": name}
                ),
                template=client.V1PodTemplateSpec(
                    metadata=client.V1ObjectMeta(labels={"app": name}),
                    spec=pod_spec
                )
            )
        )
    
    async def _create_namespace(self, namespace: str):
        body = client.V1Namespace(
            metadata=client.V1ObjectMeta(name=namespace)
        )
        try:
            await asyncio.to_thread(self.v1.create_namespace, body=body)
        except ApiException as e:
            if e.status != 409:  # Already exists
                raise
    
    async def _create_pvc(self, namespace: str, name: str):
        pvc = client.V1PersistentVolumeClaim(
            api_version="v1",
            kind="PersistentVolumeClaim",
            metadata=client.V1ObjectMeta(name=name, namespace=namespace),
            spec=client.V1PersistentVolumeClaimSpec(
                access_modes=["ReadWriteOnce"],
                resources=client.V1ResourceRequirements(
                    requests={"storage": "10Gi"}
                )
            )
        )
        try:
            await asyncio.to_thread(
                self.v1.create_namespaced_persistent_volume_claim,
                namespace=namespace,
                body=pvc
            )
        except ApiException as e:
            if e.status != 409:
                raise
    
    async def _create_deployment(self, namespace: str, deployment: client.V1Deployment):
        try:
            await asyncio.to_thread(
                self.apps_v1.create_namespaced_deployment,
                namespace=namespace,
                body=deployment
            )
        except ApiException as e:
            if e.status != 409:
                raise
    
    async def _create_service(self, namespace: str, name: str):
        service = client.V1Service(
            api_version="v1",
            kind="Service",
            metadata=client.V1ObjectMeta(name=name, namespace=namespace),
            spec=client.V1ServiceSpec(
                selector={"app": name},
                ports=[
                    client.V1ServicePort(
                        port=80,
                        target_port=8080
                    )
                ]
            )
        )
        try:
            await asyncio.to_thread(
                self.v1.create_namespaced_service,
                namespace=namespace,
                body=service
            )
        except ApiException as e:
            if e.status != 409:
                raise
    
    async def _wait_for_pod(self, namespace: str, deployment_name: str, timeout: int = 300):
        """Wait for pod to be ready"""
        start_time = asyncio.get_event_loop().time()
        
        while (asyncio.get_event_loop().time() - start_time) < timeout:
            pods = await asyncio.to_thread(
                self.v1.list_namespaced_pod,
                namespace=namespace,
                label_selector=f"app={deployment_name}"
            )
            
            for pod in pods.items:
                if pod.status.phase == "Running":
                    # Check if all containers are ready
                    if all(c.ready for c in pod.status.container_statuses or []):
                        return pod.metadata.name
            
            await asyncio.sleep(2)
        
        raise TimeoutError(f"Pod for {deployment_name} not ready after {timeout}s")
    
    def exec_in_pod_stream(self, namespace: str, pod_name: str, container: str, command: list):
        """Create exec stream for pod - returns websocket connection"""
        return stream(
            self.v1.connect_get_namespaced_pod_exec,
            pod_name,
            namespace,
            container=container,
            command=command,
            stderr=True,
            stdin=True,
            stdout=True,
            tty=True,
            _preload_content=False
        )

# Singleton instance
k8s_service = K8sService()
```

## 4. WebSocket Handler

```python
# app/api/websocket.py
from fastapi import WebSocket, WebSocketDisconnect, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import asyncio
import logging
from typing import Optional
from ..services.k8s_service import k8s_service
from ..core.security import verify_token

logger = logging.getLogger(__name__)
security = HTTPBearer()

class WebSocketManager:
    def __init__(self):
        self.active_connections: dict = {}
    
    async def connect(self, websocket: WebSocket, connection_id: str):
        await websocket.accept()
        self.active_connections[connection_id] = websocket
    
    def disconnect(self, connection_id: str):
        if connection_id in self.active_connections:
            del self.active_connections[connection_id]
    
    async def send_data(self, connection_id: str, data: bytes):
        if connection_id in self.active_connections:
            websocket = self.active_connections[connection_id]
            await websocket.send_bytes(data)

manager = WebSocketManager()

async def websocket_endpoint(
    websocket: WebSocket,
    namespace: str,
    pod_name: str,
    container: str = "dev-container",
    token: Optional[str] = None
):
    # Verify authentication
    if not token:
        await websocket.close(code=1008, reason="Missing authentication")
        return
    
    try:
        user = verify_token(token)
        if not user:
            await websocket.close(code=1008, reason="Invalid token")
            return
    except Exception as e:
        await websocket.close(code=1008, reason="Authentication failed")
        return
    
    connection_id = f"{namespace}-{pod_name}-{id(websocket)}"
    
    try:
        # Accept WebSocket connection
        await manager.connect(websocket, connection_id)
        logger.info(f"WebSocket connected: {connection_id}")
        
        # Create K8s exec stream
        k8s_stream = k8s_service.exec_in_pod_stream(
            namespace=namespace,
            pod_name=pod_name,
            container=container,
            command=["/bin/bash"]
        )
        
        # Create tasks for bidirectional communication
        async def k8s_to_client():
            """Forward data from K8s to WebSocket client"""
            try:
                while k8s_stream.is_open():
                    k8s_stream.update(timeout=0)
                    if k8s_stream.peek_stdout():
                        data = k8s_stream.read_stdout()
                        await websocket.send_text(data)
                    if k8s_stream.peek_stderr():
                        data = k8s_stream.read_stderr()
                        await websocket.send_text(data)
                    await asyncio.sleep(0.01)
            except Exception as e:
                logger.error(f"K8s to client error: {e}")
        
        async def client_to_k8s():
            """Forward data from WebSocket client to K8s"""
            try:
                while True:
                    data = await websocket.receive_text()
                    if k8s_stream.is_open():
                        k8s_stream.write_stdin(data)
            except WebSocketDisconnect:
                logger.info(f"Client disconnected: {connection_id}")
            except Exception as e:
                logger.error(f"Client to K8s error: {e}")
        
        # Run both tasks concurrently
        await asyncio.gather(
            k8s_to_client(),
            client_to_k8s()
        )
        
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        manager.disconnect(connection_id)
        if 'k8s_stream' in locals() and k8s_stream:
            k8s_stream.close()
```

## 5. FastAPI Server Setup

```python
# app/main.py
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
from .api import auth, deployments, websocket
from .core.config import settings
from .core.database import connect_to_mongo, close_mongo_connection

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await connect_to_mongo()
    logger.info("Connected to MongoDB")
    yield
    # Shutdown
    await close_mongo_connection()
    logger.info("Disconnected from MongoDB")

# Create FastAPI app
app = FastAPI(
    title="K8s Terminal API",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(deployments.router, prefix="/api/deployments", tags=["deployments"])

# WebSocket endpoint
@app.websocket("/ws/exec/{namespace}/{pod_name}")
async def websocket_exec(
    websocket: WebSocket,
    namespace: str,
    pod_name: str,
    container: str = "dev-container",
    token: str = None
):
    await websocket_endpoint(
        websocket=websocket,
        namespace=namespace,
        pod_name=pod_name,
        container=container,
        token=token
    )

# Health check
@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

## 6. Deployment Endpoints

```python
# app/api/deployments.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..models.deployment import DeploymentCreate, DeploymentResponse
from ..services.k8s_service import k8s_service
from ..core.database import get_database
from ..middleware.auth import get_current_user
from ..models.user import User
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/create", response_model=DeploymentResponse)
async def create_deployment(
    current_user: User = Depends(get_current_user),
    db = Depends(get_database)
):
    """Create a new K8s deployment for user"""
    try:
        # Create K8s resources
        deployment_info = await k8s_service.create_user_environment(
            user_id=str(current_user.id)
        )
        
        # Save to database
        deployment_doc = {
            "user_id": str(current_user.id),
            **deployment_info,
            "created_at": datetime.utcnow(),
            "status": "active"
        }
        
        result = await db.deployments.insert_one(deployment_doc)
        deployment_doc["_id"] = result.inserted_id
        
        return DeploymentResponse(**deployment_doc)
        
    except Exception as e:
        logger.error(f"Failed to create deployment: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create deployment: {str(e)}"
        )

@router.get("/list", response_model=List[DeploymentResponse])
async def list_deployments(
    current_user: User = Depends(get_current_user),
    db = Depends(get_database)
):
    """List all deployments for current user"""
    deployments = await db.deployments.find(
        {"user_id": str(current_user.id)}
    ).to_list(100)
    
    return [DeploymentResponse(**d) for d in deployments]

@router.delete("/{deployment_id}")
async def delete_deployment(
    deployment_id: str,
    current_user: User = Depends(get_current_user),
    db = Depends(get_database)
):
    """Delete a deployment"""
    # Verify ownership
    deployment = await db.deployments.find_one({
        "_id": deployment_id,
        "user_id": str(current_user.id)
    })
    
    if not deployment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Deployment not found"
        )
    
    # Delete K8s resources
    # TODO: Implement K8s cleanup
    
    # Delete from database
    await db.deployments.delete_one({"_id": deployment_id})
    
    return {"message": "Deployment deleted successfully"}
```

## 7. Configuration

```python
# app/core/config.py
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # App settings
    APP_NAME: str = "K8s Terminal API"
    DEBUG: bool = False
    
    # Server settings
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database
    MONGODB_URL: str
    DATABASE_NAME: str = "k8s_terminal"
    
    # CORS
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000"]
    
    # Kubernetes
    K8S_NAMESPACE_PREFIX: str = "user-"
    
    class Config:
        env_file = ".env"

settings = Settings()
```

## 8. Docker Configuration

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app/ ./app/

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 9. Running the Server

```bash
# Development
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Production với Gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000

# Docker
docker build -t k8s-terminal-api .
docker run -p 8000:8000 --env-file .env k8s-terminal-api
```

## 10. WebSocket Client Example (Python)

```python
# Example WebSocket client
import asyncio
import websockets
import json

async def test_terminal():
    uri = "ws://localhost:8000/ws/exec/user-123/dev-env-123-pod?token=YOUR_TOKEN"
    
    async with websockets.connect(uri) as websocket:
        # Send a command
        await websocket.send("ls -la\n")
        
        # Receive output
        while True:
            message = await websocket.recv()
            print(f"Received: {message}")

asyncio.run(test_terminal())
```

## Key Advantages của Python Implementation:

1. **Async Native**: FastAPI & Python asyncio xử lý concurrent connections tốt
2. **Type Safety**: Pydantic models ensure data validation
3. **Performance**: Uvicorn với uvloop cho performance cao
4. **Simple Deployment**: Dễ containerize và deploy
5. **Rich Ecosystem**: Nhiều libraries cho K8s, monitoring, etc.

## Notes:
- Dùng `motor` thay vì `pymongo` cho async MongoDB operations
- WebSocket implementation dùng native FastAPI WebSocket
- K8s Python client mature và stable
- Consider thêm Redis cho session management nếu scale lớn