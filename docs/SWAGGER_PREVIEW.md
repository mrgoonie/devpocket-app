# DevPocket API - Swagger/ReDoc Documentation Preview

## Overview
The DevPocket API now includes comprehensive OpenAPI documentation available at:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

## Enhanced Documentation Features

### 🎨 Templates API Documentation

#### GET /api/v1/templates
- **Summary**: List all templates
- **Description**: Get a list of all available environment templates with optional filtering
- **Query Parameters**:
  - `category`: Filter by category (with example: "programming_language")
  - `status`: Filter by status (with example: "active")
- **Response Examples**: Full template object with Python example
- **Authentication**: JWT required
- **Tags**: Templates

#### GET /api/v1/templates/{template_id}
- **Summary**: Get template by ID
- **Description**: Retrieve detailed information about a specific template
- **Path Parameter**: template_id with example "507f1f77bcf86cd799439011"
- **Response Examples**: Node.js template example
- **Error Responses**: 404 for non-existent or deprecated templates

#### POST /api/v1/templates
- **Summary**: Create a new template
- **Description**: Create a new environment template (Admin only)
- **Request Body Example**: Java 17 LTS template
- **Response**: Created template with all fields
- **Authorization**: Admin role required

#### PUT /api/v1/templates/{template_id}
- **Summary**: Update a template
- **Description**: Update an existing template (Admin only)
- **Request Body Example**: Partial update with Spring Boot additions
- **Note**: Cannot change template name once created

#### DELETE /api/v1/templates/{template_id}
- **Summary**: Delete a template
- **Description**: Soft delete by setting status to deprecated
- **Important Notes**: 
  - Templates not physically deleted
  - Existing environments continue to work

#### POST /api/v1/templates/initialize
- **Summary**: Initialize default templates
- **Description**: Initialize system with Python, Node.js, Go, Rust, Ubuntu templates
- **Admin Only**: Yes

### 🔄 Environment Restart Documentation

#### POST /api/v1/environments/{environment_id}/restart
- **Summary**: Restart an environment
- **Description**: Restart a development environment by recreating its container
- **Process Steps**:
  1. Status changes to 'creating'
  2. Container/pod recreated
  3. Status returns to 'running'
- **Requirements**: Environment must be in running/stopped/error state
- **Response Example**: Success message
- **Error Cases**: 400 for invalid state
- **Tags**: Environment Management

### 📋 Environment Logs Documentation

#### GET /api/v1/environments/{environment_id}/logs
- **Summary**: Get environment logs
- **Description**: Retrieve logs from a development environment
- **Query Parameters**:
  - `lines`: Number of lines (1-1000, default: 100)
  - `since`: ISO timestamp filter (example: "2024-01-01T12:00:00Z")
- **Response Example**:
  ```json
  {
    "environment_id": "507f1f77bcf86cd799439011",
    "environment_name": "my-python-env",
    "logs": [
      {
        "timestamp": "2024-01-01T12:00:00Z",
        "level": "INFO",
        "message": "Starting Python application server",
        "source": "container"
      }
    ],
    "total_lines": 2,
    "has_more": false
  }
  ```
- **Log Levels**: INFO, DEBUG, WARNING, ERROR
- **Tags**: Environment Monitoring

## Request/Response Models

### TemplateCreate Model
```json
{
  "name": "java",
  "display_name": "Java 17 LTS",
  "description": "Java development environment with Maven and Gradle support",
  "category": "programming_language",
  "tags": ["java", "jvm", "maven", "gradle", "spring"],
  "docker_image": "openjdk:17-slim",
  "default_port": 8080,
  "default_resources": {
    "cpu": "1000m",
    "memory": "2Gi",
    "storage": "15Gi"
  },
  "environment_variables": {
    "JAVA_HOME": "/usr/local/openjdk-17",
    "MAVEN_HOME": "/usr/share/maven"
  },
  "startup_commands": [
    "apt-get update && apt-get install -y maven gradle",
    "mkdir -p /workspace"
  ],
  "documentation_url": "https://docs.oracle.com/en/java/",
  "icon_url": "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/java/java-original.svg"
}
```

### TemplateUpdate Model
```json
{
  "description": "Updated Java development environment with Spring Boot support",
  "tags": ["java", "spring-boot", "microservices"],
  "environment_variables": {
    "JAVA_HOME": "/usr/local/openjdk-17",
    "SPRING_PROFILES_ACTIVE": "dev"
  },
  "status": "active"
}
```

## Interactive Features in Swagger UI

1. **Try it out**: Execute API calls directly from the browser
2. **Authentication**: Lock icon to add JWT token
3. **Parameter Examples**: Pre-filled example values
4. **Response Visualization**: Formatted JSON responses
5. **Error Examples**: See all possible error responses
6. **Model Schemas**: Expandable model definitions

## ReDoc Features

1. **Three-panel layout**: Navigation, documentation, code samples
2. **Search functionality**: Find endpoints quickly
3. **Deep linking**: Share direct links to specific endpoints
4. **Code generation**: Download OpenAPI spec for client generation
5. **Dark mode**: Better readability

## Testing the Documentation

1. Start the server:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

2. Open Swagger UI:
   ```
   http://localhost:8000/docs
   ```

3. Open ReDoc:
   ```
   http://localhost:8000/redoc
   ```

4. Authenticate:
   - Click "Authorize" button
   - Enter JWT token: `Bearer <your-token>`

5. Test endpoints:
   - Click endpoint
   - Click "Try it out"
   - Fill parameters
   - Click "Execute"

## Benefits

- **Developer Experience**: Interactive API testing without external tools
- **Client Generation**: Generate SDKs in any language from OpenAPI spec
- **API Contract**: Clear documentation of request/response formats
- **Validation**: Automatic request validation based on schemas
- **Examples**: Real-world examples for every endpoint
- **Error Documentation**: All possible error responses documented

The documentation is now production-ready and provides a professional API experience for developers!