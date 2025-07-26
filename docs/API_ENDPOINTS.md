# DevPocket API Endpoints

## Overview
This document lists all available API endpoints in the DevPocket server.

## Base URL
- Development: `http://localhost:8000`
- Production: Your deployed server URL

## Authentication
Most endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## Health Check Endpoints

### GET /health
Health check endpoint
- **Authentication:** Not required
- **Returns:** Service health status with version and environment info

### GET /health/ready
Readiness check for Kubernetes
- **Authentication:** Not required  
- **Returns:** Service readiness status with database connectivity check

### GET /health/live
Liveness check for Kubernetes
- **Authentication:** Not required
- **Returns:** Basic service availability status

### GET /api/v1/info
API information endpoint
- **Authentication:** Not required
- **Returns:** API metadata and version information

## Authentication API

### POST /api/v1/auth/register
Register a new user account
- **Authentication:** Not required
- **Body:** User registration data (username, email, password, full_name)
- **Returns:** Created user object
- **Status:** 201 Created

### POST /api/v1/auth/login
User login with email/password
- **Authentication:** Not required
- **Body:** Login credentials (email, password)
- **Returns:** JWT tokens (access_token, refresh_token) and user info
- **Status:** 200 OK

### POST /api/v1/auth/google
Google OAuth login
- **Authentication:** Not required
- **Body:** Google OAuth token
- **Returns:** JWT tokens and user info
- **Status:** 200 OK

### GET /api/v1/auth/me
Get current user information
- **Authentication:** Required
- **Returns:** Current user profile data
- **Status:** 200 OK

### POST /api/v1/auth/logout
Logout user (invalidate tokens)
- **Authentication:** Required
- **Returns:** Success message
- **Status:** 200 OK

### POST /api/v1/auth/refresh
Refresh JWT access token
- **Authentication:** Refresh token required
- **Body:** Refresh token
- **Returns:** New access token
- **Status:** 200 OK

### POST /api/v1/auth/verify-email
Verify user email address
- **Authentication:** Not required
- **Body:** Email verification token
- **Returns:** Success message
- **Status:** 200 OK

### POST /api/v1/auth/resend-verification
Resend email verification
- **Authentication:** Required
- **Returns:** Success message
- **Status:** 200 OK

## Environments API

### POST /api/v1/environments
Create a new development environment
- **Authentication:** Required
- **Body:** Environment creation data (name, template_id, etc.)
- **Returns:** Created environment object
- **Status:** 201 Created

### GET /api/v1/environments
List user's environments
- **Authentication:** Required
- **Query Parameters:**
  - `status`: Filter by status (creating, running, stopped, error)
  - `template_id`: Filter by template
- **Returns:** Array of environment objects

### GET /api/v1/environments/{environment_id}
Get specific environment details
- **Authentication:** Required
- **Returns:** Environment object with full details

### PUT /api/v1/environments/{environment_id}
Update an existing environment
- **Authentication:** Required
- **Body:** Environment update data
- **Returns:** Updated environment object

### DELETE /api/v1/environments/{environment_id}
Delete an environment
- **Authentication:** Required
- **Returns:** Success message
- **Status:** 204 No Content

### POST /api/v1/environments/{environment_id}/start
Start an environment
- **Authentication:** Required
- **Returns:** Success message
- **Note:** Environment must be in stopped state

### POST /api/v1/environments/{environment_id}/stop
Stop an environment
- **Authentication:** Required
- **Returns:** Success message
- **Note:** Environment must be in running state

### POST /api/v1/environments/{environment_id}/restart
Restart an environment
- **Authentication:** Required
- **Returns:** Success message
- **Note:** Environment must be in running, stopped, or error state

### GET /api/v1/environments/{environment_id}/metrics
Get environment resource usage metrics
- **Authentication:** Required
- **Returns:** Environment metrics data (CPU, memory, storage usage)

### GET /api/v1/environments/{environment_id}/logs
Get environment logs
- **Query Parameters:**
  - `lines`: Number of log lines to retrieve (1-1000, default: 100)
  - `since`: Get logs since timestamp (ISO format, e.g., 2024-01-01T12:00:00Z)
- **Authentication:** Required
- **Returns:** Log entries with metadata

## Templates API
Manage environment templates for different programming languages and frameworks.

### GET /api/v1/templates
List all available templates
- **Query Parameters:**
  - `category`: Filter by category (programming_language, framework, database, devops, operating_system)
  - `status`: Filter by status (active, deprecated, beta)
- **Authentication:** Required
- **Returns:** Array of template objects

### GET /api/v1/templates/{template_id}
Get specific template details
- **Authentication:** Required
- **Returns:** Template object with full details

### POST /api/v1/templates
Create a new template (Admin only)
- **Authentication:** Admin required
- **Body:** Template creation data
- **Returns:** Created template object

### PUT /api/v1/templates/{template_id}
Update an existing template (Admin only)
- **Authentication:** Admin required
- **Body:** Template update data
- **Returns:** Updated template object

### DELETE /api/v1/templates/{template_id}
Delete a template (Admin only) - Sets status to deprecated
- **Authentication:** Admin required
- **Returns:** Success message

### POST /api/v1/templates/initialize
Initialize default templates (Admin only)
- **Authentication:** Admin required
- **Returns:** Success message

## Clusters API
Manage Kubernetes clusters for environment deployment.

### POST /api/v1/clusters
Create a new cluster
- **Authentication:** Admin required
- **Body:** Cluster configuration data
- **Returns:** Created cluster object
- **Status:** 201 Created

### GET /api/v1/clusters
List all clusters
- **Authentication:** Admin required
- **Returns:** Array of cluster objects

### GET /api/v1/clusters/regions
Get available regions for cluster deployment
- **Authentication:** Admin required
- **Returns:** Array of available regions

### GET /api/v1/clusters/{cluster_id}
Get specific cluster details
- **Authentication:** Admin required
- **Returns:** Cluster object with full details

### PUT /api/v1/clusters/{cluster_id}
Update an existing cluster
- **Authentication:** Admin required
- **Body:** Cluster update data
- **Returns:** Updated cluster object

### DELETE /api/v1/clusters/{cluster_id}
Delete a cluster
- **Authentication:** Admin required
- **Returns:** Success message
- **Status:** 204 No Content

### GET /api/v1/clusters/{cluster_id}/health
Check cluster health status
- **Authentication:** Admin required
- **Returns:** Cluster health check results

## WebSocket API
Real-time communication endpoints for terminal and log streaming.

### WebSocket /api/v1/ws/terminal/{environment_id}
Terminal access to environment
- **Authentication:** JWT token via query parameter `?token=jwt_token`
- **Messages:**
  - `{"type": "input", "data": "command\n"}` - Send terminal input
  - `{"type": "resize", "cols": 80, "rows": 24}` - Resize terminal
  - `{"type": "ping"}` - Keepalive (responds with pong)
- **Returns:** Real-time terminal output

### WebSocket /api/v1/ws/logs/{environment_id}
Real-time log streaming from environment
- **Authentication:** JWT token via query parameter `?token=jwt_token`
- **Messages:**
  - `{"type": "subscribe"}` - Start log streaming
  - `{"type": "unsubscribe"}` - Stop log streaming
- **Returns:** Real-time log output

## Default Templates

The system includes these default templates:

### Python 3.11
- **Image:** python:3.11-slim
- **Port:** 8080
- **Includes:** pip, virtualenv, Flask, Django support
- **Resources:** 500m CPU, 1Gi memory, 10Gi storage

### Node.js 18 LTS
- **Image:** node:18-slim
- **Port:** 3000
- **Includes:** npm, yarn, Express, React, Vue support
- **Resources:** 500m CPU, 1Gi memory, 10Gi storage

### Go 1.21
- **Image:** golang:1.21-alpine
- **Port:** 8080
- **Includes:** Go compiler, air for hot reload
- **Resources:** 500m CPU, 1Gi memory, 10Gi storage

### Rust Latest
- **Image:** rust:latest
- **Port:** 8080
- **Includes:** rustc, cargo, cargo-watch
- **Resources:** 1000m CPU, 2Gi memory, 15Gi storage

### Ubuntu 22.04 LTS
- **Image:** ubuntu:22.04
- **Port:** 8080
- **Includes:** Essential development tools
- **Resources:** 500m CPU, 1Gi memory, 10Gi storage

## Response Formats

### User Response Object
```json
{
  "id": "string",
  "username": "string",
  "email": "string",
  "full_name": "string",
  "is_active": true,
  "is_verified": false,
  "avatar_url": "string",
  "subscription_plan": "free",
  "created_at": "2024-01-01T00:00:00Z",
  "last_login": "2024-01-01T00:00:00Z"
}
```

### Environment Object
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "template_id": "string",
  "template_name": "string",
  "status": "running",
  "docker_image": "string",
  "port": 8080,
  "resources": {
    "cpu": "500m",
    "memory": "1Gi", 
    "storage": "10Gi"
  },
  "environment_variables": {},
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "last_activity": "2024-01-01T00:00:00Z"
}
```

### Template Object
```json
{
  "id": "string",
  "name": "string",
  "display_name": "string",
  "description": "string",
  "category": "programming_language",
  "tags": ["array", "of", "strings"],
  "docker_image": "string",
  "default_port": 8080,
  "default_resources": {
    "cpu": "500m",
    "memory": "1Gi",
    "storage": "10Gi"
  },
  "environment_variables": {},
  "startup_commands": ["array", "of", "commands"],
  "documentation_url": "string",
  "icon_url": "string",
  "status": "active",
  "version": "1.0.0",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "usage_count": 0
}
```

### Cluster Object
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "provider": "ovh",
  "region": "string",
  "kubeconfig": "encrypted_string",
  "status": "active",
  "node_count": 3,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### Log Response
```json
{
  "environment_id": "string",
  "environment_name": "string",
  "logs": [
    {
      "timestamp": "2024-01-01T00:00:00Z",
      "level": "INFO",
      "message": "Application started successfully",
      "source": "container"
    }
  ],
  "total_lines": 100,
  "has_more": false
}
```

### Token Response
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "string",
    "username": "string",
    "email": "string"
  }
}
```

## Error Responses

All endpoints return structured error responses:
```json
{
  "detail": "Error message",
  "errors": [] // For validation errors
}
```

Common HTTP status codes:
- `200`: Success
- `201`: Created
- `204`: No Content
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden (Admin required)
- `404`: Not Found
- `422`: Validation Error
- `429`: Too Many Requests (Rate Limited)
- `500`: Internal Server Error
- `503`: Service Unavailable

## Rate Limiting

API endpoints are rate limited to prevent abuse:
- Authentication endpoints: 5 requests per minute
- General API endpoints: 100 requests per minute
- WebSocket connections: 10 connections per user

Rate limit headers are included in responses:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Remaining requests in current window
- `X-RateLimit-Reset`: Time when rate limit resets