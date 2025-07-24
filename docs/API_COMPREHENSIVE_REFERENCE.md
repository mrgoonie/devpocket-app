# DevPocket API - Comprehensive Reference

## Overview

This document provides a complete technical reference for the DevPocket API (v1). The API enables developers to manage development environments, user authentication, templates, and clusters programmatically.

**Base URL**: `https://devpocket-api.goon.vn`  
**OpenAPI Version**: 3.1.0  
**API Version**: 1.0.0

## Table of Contents

1. [Authentication](#authentication)
2. [Health Check](#health-check)
3. [Authentication Endpoints](#authentication-endpoints)
4. [User Management](#user-management)
5. [Environment Management](#environment-management)
6. [Template Management](#template-management)
7. [Cluster Management](#cluster-management)
8. [WebSocket Endpoints](#websocket-endpoints)
9. [Data Models](#data-models)
10. [Error Handling](#error-handling)
11. [Rate Limiting & Security](#rate-limiting--security)

## Authentication

The API supports two authentication methods:

### JWT Bearer Token
Most endpoints require JWT authentication. Include the token in the Authorization header:
```http
Authorization: Bearer <your-jwt-token>
```

### Google OAuth
Available for authentication endpoints using Google Sign-In flow.

## Health Check

### GET /api/v1/health
Check API health status.

**Authentication**: None required  
**Response**: 
```json
{
  "status": "healthy",
  "timestamp": "2024-07-24T00:00:00Z",
  "version": "1.0.0"
}
```

## Authentication Endpoints

### POST /api/v1/auth/register
Register a new user account.

**Authentication**: None required  
**Content-Type**: `application/json`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "full_name": "John Doe"
}
```

**Response (201)**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "full_name": "John Doe",
    "is_verified": false,
    "created_at": "2024-07-24T00:00:00Z",
    "updated_at": "2024-07-24T00:00:00Z"
  }
}
```

**Error Responses**:
- `400`: Validation error (email already exists, weak password)
- `422`: Invalid request data

### POST /api/v1/auth/login
Authenticate user with email and password.

**Authentication**: None required  
**Content-Type**: `application/json`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200)**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "full_name": "John Doe",
    "is_verified": true,
    "created_at": "2024-07-24T00:00:00Z",
    "updated_at": "2024-07-24T00:00:00Z"
  }
}
```

**Error Responses**:
- `401`: Invalid credentials
- `422`: Invalid request data

### POST /api/v1/auth/google
Authenticate user with Google OAuth token.

**Authentication**: None required  
**Content-Type**: `application/json`

**Request Body**:
```json
{
  "token": "google_oauth_token_here"
}
```

**Response (200)**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@gmail.com",
    "full_name": "John Doe",
    "is_verified": true,
    "created_at": "2024-07-24T00:00:00Z",
    "updated_at": "2024-07-24T00:00:00Z"
  }
}
```

**Error Responses**:
- `400`: Invalid Google token
- `422`: Invalid request data

### POST /api/v1/auth/logout
Logout user and invalidate tokens.

**Authentication**: Bearer token required

**Response (200)**:
```json
{
  "message": "Successfully logged out"
}
```

### GET /api/v1/auth/me
Get current user information.

**Authentication**: Bearer token required

**Response (200)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "full_name": "John Doe",
  "is_verified": true,
  "created_at": "2024-07-24T00:00:00Z",
  "updated_at": "2024-07-24T00:00:00Z"
}
```

**Error Responses**:
- `401`: Invalid or expired token

### POST /api/v1/auth/verify-email
Send email verification link.

**Authentication**: Bearer token required

**Response (200)**:
```json
{
  "message": "Verification email sent"
}
```

## User Management

### PUT /api/v1/users/me
Update current user profile.

**Authentication**: Bearer token required  
**Content-Type**: `application/json`

**Request Body**:
```json
{
  "full_name": "John Updated Doe",
  "email": "updated@example.com"
}
```

**Response (200)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "updated@example.com",
  "full_name": "John Updated Doe",
  "is_verified": true,
  "created_at": "2024-07-24T00:00:00Z",
  "updated_at": "2024-07-24T00:00:00Z"
}
```

**Error Responses**:
- `400`: Email already exists
- `401`: Unauthorized
- `422`: Invalid request data

### DELETE /api/v1/users/me
Delete current user account.

**Authentication**: Bearer token required

**Response (200)**:
```json
{
  "message": "User account deleted successfully"
}
```

**Error Responses**:
- `401`: Unauthorized

## Environment Management

### GET /api/v1/environments
List all user environments.

**Authentication**: Bearer token required

**Query Parameters**:
- `status` (optional): Filter by status (`creating`, `running`, `stopped`, `error`, `deleting`)
- `template_id` (optional): Filter by template ID
- `limit` (optional, default: 50): Number of environments to return
- `offset` (optional, default: 0): Number of environments to skip

**Response (200)**:
```json
{
  "environments": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "my-python-env",
      "status": "running",
      "template_id": "python-3.11",
      "cluster_id": "default-cluster",
      "resources": {
        "cpu": "500m",
        "memory": "1Gi",
        "storage": "10Gi"
      },
      "port": 8080,
      "url": "https://my-python-env.devpocket-api.goon.vn",
      "created_at": "2024-07-24T00:00:00Z",
      "updated_at": "2024-07-24T00:00:00Z"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

### POST /api/v1/environments
Create a new environment.

**Authentication**: Bearer token required  
**Content-Type**: `application/json`

**Request Body**:
```json
{
  "name": "my-new-environment",
  "template_id": "python-3.11",
  "cluster_id": "default-cluster",
  "resources": {
    "cpu": "1000m",
    "memory": "2Gi",
    "storage": "20Gi"
  },
  "environment_variables": {
    "DEBUG": "true",
    "DATABASE_URL": "postgresql://..."
  }
}
```

**Response (201)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "my-new-environment",
  "status": "creating",
  "template_id": "python-3.11",
  "cluster_id": "default-cluster",
  "resources": {
    "cpu": "1000m",
    "memory": "2Gi",
    "storage": "20Gi"
  },
  "port": 8080,
  "url": null,
  "environment_variables": {
    "DEBUG": "true",
    "DATABASE_URL": "postgresql://..."
  },
  "created_at": "2024-07-24T00:00:00Z",
  "updated_at": "2024-07-24T00:00:00Z"
}
```

**Error Responses**:
- `400`: Invalid template or cluster ID
- `401`: Unauthorized
- `422`: Invalid request data

### GET /api/v1/environments/{environment_id}
Get specific environment details.

**Authentication**: Bearer token required

**Path Parameters**:
- `environment_id`: UUID of the environment

**Response (200)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "my-python-env",
  "status": "running",
  "template_id": "python-3.11",
  "cluster_id": "default-cluster",
  "resources": {
    "cpu": "500m",
    "memory": "1Gi",
    "storage": "10Gi"
  },
  "port": 8080,
  "url": "https://my-python-env.devpocket-api.goon.vn",
  "environment_variables": {
    "DEBUG": "true"
  },
  "created_at": "2024-07-24T00:00:00Z",
  "updated_at": "2024-07-24T00:00:00Z"
}
```

**Error Responses**:
- `401`: Unauthorized
- `404`: Environment not found

### PUT /api/v1/environments/{environment_id}
Update an existing environment.

**Authentication**: Bearer token required  
**Content-Type**: `application/json`

**Path Parameters**:
- `environment_id`: UUID of the environment

**Request Body**:
```json
{
  "name": "updated-environment-name",
  "resources": {
    "cpu": "1000m",
    "memory": "2Gi",
    "storage": "20Gi"
  },
  "environment_variables": {
    "DEBUG": "false",
    "NEW_VAR": "value"
  }
}
```

**Response (200)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "updated-environment-name",
  "status": "running",
  "template_id": "python-3.11",
  "cluster_id": "default-cluster",
  "resources": {
    "cpu": "1000m",
    "memory": "2Gi",
    "storage": "20Gi"
  },
  "port": 8080,
  "url": "https://updated-environment-name.devpocket-api.goon.vn",
  "environment_variables": {
    "DEBUG": "false",
    "NEW_VAR": "value"
  },
  "created_at": "2024-07-24T00:00:00Z",
  "updated_at": "2024-07-24T00:00:00Z"
}
```

**Error Responses**:
- `401`: Unauthorized
- `404`: Environment not found
- `422`: Invalid request data

### DELETE /api/v1/environments/{environment_id}
Delete an environment.

**Authentication**: Bearer token required

**Path Parameters**:
- `environment_id`: UUID of the environment

**Response (200)**:
```json
{
  "message": "Environment deleted successfully"
}
```

**Error Responses**:
- `401`: Unauthorized
- `404`: Environment not found

### POST /api/v1/environments/{environment_id}/start
Start a stopped environment.

**Authentication**: Bearer token required

**Path Parameters**:
- `environment_id`: UUID of the environment

**Response (200)**:
```json
{
  "message": "Environment start initiated",
  "status": "creating"
}
```

**Error Responses**:
- `400`: Environment cannot be started (invalid state)
- `401`: Unauthorized
- `404`: Environment not found

### POST /api/v1/environments/{environment_id}/stop
Stop a running environment.

**Authentication**: Bearer token required

**Path Parameters**:
- `environment_id`: UUID of the environment

**Response (200)**:
```json
{
  "message": "Environment stop initiated",
  "status": "stopping"
}
```

**Error Responses**:
- `400`: Environment cannot be stopped (invalid state)
- `401`: Unauthorized
- `404`: Environment not found

### POST /api/v1/environments/{environment_id}/restart
Restart an environment.

**Authentication**: Bearer token required

**Path Parameters**:
- `environment_id`: UUID of the environment

**Response (200)**:
```json
{
  "message": "Environment restart initiated",
  "status": "restarting"
}
```

**Error Responses**:
- `400`: Environment cannot be restarted (invalid state)
- `401`: Unauthorized
- `404`: Environment not found

### GET /api/v1/environments/{environment_id}/logs
Get environment logs.

**Authentication**: Bearer token required

**Path Parameters**:
- `environment_id`: UUID of the environment

**Query Parameters**:
- `lines` (optional, default: 100): Number of log lines (1-1000)
- `since` (optional): Get logs since timestamp (ISO format)
- `follow` (optional, default: false): Stream logs in real-time

**Response (200)**:
```json
{
  "environment_id": "550e8400-e29b-41d4-a716-446655440000",
  "environment_name": "my-python-env",
  "logs": [
    {
      "timestamp": "2024-07-24T00:00:00Z",
      "level": "INFO",
      "message": "Application started successfully",
      "source": "container"
    },
    {
      "timestamp": "2024-07-24T00:01:00Z",
      "level": "INFO",
      "message": "Server listening on port 8080",
      "source": "application"
    }
  ],
  "total_lines": 150,
  "has_more": true
}
```

**Error Responses**:
- `401`: Unauthorized
- `404`: Environment not found

## Template Management

### GET /api/v1/templates
List all available templates.

**Authentication**: Bearer token required

**Query Parameters**:
- `category` (optional): Filter by category (`programming_language`, `framework`, `database`, `devops`, `operating_system`)
- `status` (optional): Filter by status (`active`, `deprecated`, `beta`)
- `limit` (optional, default: 50): Number of templates to return
- `offset` (optional, default: 0): Number of templates to skip

**Response (200)**:
```json
{
  "templates": [
    {
      "id": "python-3.11",
      "name": "python-3.11",
      "display_name": "Python 3.11",
      "description": "Python 3.11 development environment with pip and common packages",
      "category": "programming_language",
      "tags": ["python", "web", "data-science"],
      "docker_image": "python:3.11-slim",
      "default_port": 8080,
      "default_resources": {
        "cpu": "500m",
        "memory": "1Gi",
        "storage": "10Gi"
      },
      "environment_variables": {
        "PYTHONPATH": "/app",
        "PYTHONUNBUFFERED": "1"
      },
      "startup_commands": [
        "pip install --upgrade pip",
        "pip install flask fastapi"
      ],
      "documentation_url": "https://docs.python.org/3.11/",
      "icon_url": "https://www.python.org/static/img/python-logo.png",
      "status": "active",
      "version": "1.0.0",
      "created_at": "2024-07-24T00:00:00Z",
      "updated_at": "2024-07-24T00:00:00Z",
      "usage_count": 150
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

### GET /api/v1/templates/{template_id}
Get specific template details.

**Authentication**: Bearer token required

**Path Parameters**:
- `template_id`: ID of the template

**Response (200)**: Same as individual template object above

**Error Responses**:
- `401`: Unauthorized
- `404`: Template not found

### POST /api/v1/templates
Create a new template (Admin only).

**Authentication**: Bearer token required (Admin role)  
**Content-Type**: `application/json`

**Request Body**:
```json
{
  "id": "nodejs-18",
  "name": "nodejs-18",
  "display_name": "Node.js 18 LTS",
  "description": "Node.js 18 LTS with npm and yarn",
  "category": "programming_language",
  "tags": ["nodejs", "javascript", "web"],
  "docker_image": "node:18-slim",
  "default_port": 3000,
  "default_resources": {
    "cpu": "500m",
    "memory": "1Gi",
    "storage": "10Gi"
  },
  "environment_variables": {
    "NODE_ENV": "development"
  },
  "startup_commands": [
    "npm install -g yarn",
    "npm install"
  ],
  "documentation_url": "https://nodejs.org/docs/",
  "icon_url": "https://nodejs.org/static/images/logo.svg",
  "status": "active",
  "version": "1.0.0"
}
```

**Response (201)**: Created template object

**Error Responses**:
- `401`: Unauthorized
- `403`: Forbidden (Admin required)
- `409`: Template ID already exists
- `422`: Invalid request data

### PUT /api/v1/templates/{template_id}
Update an existing template (Admin only).

**Authentication**: Bearer token required (Admin role)  
**Content-Type**: `application/json`

**Path Parameters**:
- `template_id`: ID of the template

**Request Body**: Same as POST with updated fields

**Response (200)**: Updated template object

**Error Responses**:
- `401`: Unauthorized
- `403`: Forbidden (Admin required)
- `404`: Template not found
- `422`: Invalid request data

### DELETE /api/v1/templates/{template_id}
Delete a template (Admin only) - Sets status to deprecated.

**Authentication**: Bearer token required (Admin role)

**Path Parameters**:
- `template_id`: ID of the template

**Response (200)**:
```json
{
  "message": "Template deprecated successfully"
}
```

**Error Responses**:
- `401`: Unauthorized
- `403`: Forbidden (Admin required)
- `404`: Template not found

### POST /api/v1/templates/initialize
Initialize default templates (Admin only).

**Authentication**: Bearer token required (Admin role)

**Response (200)**:
```json
{
  "message": "Default templates initialized",
  "templates_created": 5
}
```

**Error Responses**:
- `401`: Unauthorized
- `403`: Forbidden (Admin required)

## Cluster Management

### GET /api/v1/clusters
List all available clusters.

**Authentication**: Bearer token required

**Response (200)**:
```json
{
  "clusters": [
    {
      "id": "default-cluster",
      "name": "Default Cluster",
      "description": "Primary development cluster",
      "region": "us-east-1",
      "status": "healthy",
      "capacity": {
        "total_cpu": "100000m",
        "used_cpu": "25000m",
        "total_memory": "200Gi",
        "used_memory": "50Gi",
        "total_storage": "1000Gi",
        "used_storage": "250Gi"
      },
      "node_count": 5,
      "created_at": "2024-07-24T00:00:00Z",
      "updated_at": "2024-07-24T00:00:00Z"
    }
  ]
}
```

### GET /api/v1/clusters/{cluster_id}
Get specific cluster details.

**Authentication**: Bearer token required

**Path Parameters**:
- `cluster_id`: ID of the cluster

**Response (200)**: Same as individual cluster object above

**Error Responses**:
- `401`: Unauthorized
- `404`: Cluster not found

### GET /api/v1/clusters/{cluster_id}/health
Get cluster health status.

**Authentication**: Bearer token required

**Path Parameters**:
- `cluster_id`: ID of the cluster

**Response (200)**:
```json
{
  "cluster_id": "default-cluster",
  "status": "healthy",
  "components": [
    {
      "name": "api-server",
      "status": "healthy",
      "message": "API server is responsive"
    },
    {
      "name": "node-pool",
      "status": "healthy",
      "message": "All nodes are ready"
    },
    {
      "name": "storage",
      "status": "healthy",
      "message": "Storage is available"
    }
  ],
  "last_checked": "2024-07-24T00:00:00Z"
}
```

**Error Responses**:
- `401`: Unauthorized
- `404`: Cluster not found

## WebSocket Endpoints

### WSS /api/v1/ws/terminal/{environment_id}
Establish WebSocket connection for terminal access.

**Authentication**: JWT token via query parameter or WebSocket headers
- Query parameter: `?token=<jwt_token>`
- WebSocket header: `Authorization: Bearer <jwt_token>`

**Path Parameters**:
- `environment_id`: UUID of the environment

**Connection Flow**:
1. Client establishes WebSocket connection
2. Server validates authentication
3. Server connects to environment terminal
4. Bidirectional terminal I/O through WebSocket

**Message Format**:
```json
{
  "type": "input|output|resize|error",
  "data": "terminal data or command",
  "metadata": {
    "timestamp": "2024-07-24T00:00:00Z",
    "rows": 24,
    "cols": 80
  }
}
```

**Message Types**:
- `input`: Client sending terminal input
- `output`: Server sending terminal output
- `resize`: Terminal resize event
- `error`: Error messages

**Example Messages**:
```json
// Client input
{
  "type": "input",
  "data": "ls -la\n"
}

// Server output
{
  "type": "output",
  "data": "total 8\ndrwxr-xr-x 2 user user 4096 Jul 24 00:00 .\ndrwxr-xr-x 3 user user 4096 Jul 24 00:00 ..\n"
}

// Terminal resize
{
  "type": "resize",
  "data": "",
  "metadata": {
    "rows": 30,
    "cols": 120
  }
}
```

**Error Responses**:
- `401`: Invalid or missing JWT token
- `404`: Environment not found
- `403`: Environment not accessible by user
- `503`: Terminal service unavailable

## Data Models

### User
```json
{
  "id": "string (UUID)",
  "email": "string",
  "full_name": "string",
  "is_verified": "boolean",
  "created_at": "string (ISO datetime)",
  "updated_at": "string (ISO datetime)"
}
```

### Environment
```json
{
  "id": "string (UUID)",
  "name": "string",
  "status": "string (creating|running|stopped|error|deleting)",
  "template_id": "string",
  "cluster_id": "string",
  "resources": {
    "cpu": "string (e.g., '500m')",
    "memory": "string (e.g., '1Gi')",
    "storage": "string (e.g., '10Gi')"
  },
  "port": "integer",
  "url": "string|null",
  "environment_variables": "object",
  "created_at": "string (ISO datetime)",
  "updated_at": "string (ISO datetime)"
}
```

### Template
```json
{
  "id": "string",
  "name": "string",
  "display_name": "string",
  "description": "string",
  "category": "string (programming_language|framework|database|devops|operating_system)",
  "tags": "array[string]",
  "docker_image": "string",
  "default_port": "integer",
  "default_resources": {
    "cpu": "string",
    "memory": "string",
    "storage": "string"
  },
  "environment_variables": "object",
  "startup_commands": "array[string]",
  "documentation_url": "string",
  "icon_url": "string",
  "status": "string (active|deprecated|beta)",
  "version": "string",
  "created_at": "string (ISO datetime)",
  "updated_at": "string (ISO datetime)",
  "usage_count": "integer"
}
```

### Cluster
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "region": "string",
  "status": "string (healthy|degraded|unhealthy)",
  "capacity": {
    "total_cpu": "string",
    "used_cpu": "string",
    "total_memory": "string",
    "used_memory": "string",
    "total_storage": "string",
    "used_storage": "string"
  },
  "node_count": "integer",
  "created_at": "string (ISO datetime)",
  "updated_at": "string (ISO datetime)"
}
```

### Authentication Response
```json
{
  "access_token": "string (JWT)",
  "refresh_token": "string (JWT)",
  "token_type": "string (bearer)",
  "expires_in": "integer (seconds)",
  "user": "User object"
}
```

### Log Entry
```json
{
  "timestamp": "string (ISO datetime)",
  "level": "string (DEBUG|INFO|WARN|ERROR)",
  "message": "string",
  "source": "string (container|application|system)"
}
```

## Error Handling

### Standard Error Response
All endpoints return structured error responses with consistent format:

```json
{
  "detail": "Human-readable error message",
  "errors": [
    {
      "field": "field_name",
      "message": "Field-specific error message",
      "code": "validation_code"
    }
  ],
  "timestamp": "2024-07-24T00:00:00Z",
  "path": "/api/v1/endpoint"
}
```

### HTTP Status Codes

| Code | Description | Usage |
|------|-------------|-------|
| 200 | OK | Successful GET, PUT, DELETE |
| 201 | Created | Successful POST |
| 400 | Bad Request | Invalid request data, business logic errors |
| 401 | Unauthorized | Missing, invalid, or expired authentication |
| 403 | Forbidden | Insufficient permissions (admin required) |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Resource already exists (duplicate IDs) |
| 422 | Unprocessable Entity | Request validation failed |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |
| 503 | Service Unavailable | Service temporarily unavailable |

### Common Error Scenarios

#### Authentication Errors
```json
{
  "detail": "Invalid or expired token",
  "errors": [],
  "timestamp": "2024-07-24T00:00:00Z",
  "path": "/api/v1/environments"
}
```

#### Validation Errors
```json
{
  "detail": "Request validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format",
      "code": "invalid_format"
    },
    {
      "field": "password",
      "message": "Password must be at least 8 characters",
      "code": "min_length"
    }
  ],
  "timestamp": "2024-07-24T00:00:00Z",
  "path": "/api/v1/auth/register"
}
```

#### Resource Not Found
```json
{
  "detail": "Environment not found",
  "errors": [],
  "timestamp": "2024-07-24T00:00:00Z",
  "path": "/api/v1/environments/550e8400-e29b-41d4-a716-446655440000"
}
```

#### Business Logic Errors
```json
{
  "detail": "Cannot start environment in current state",
  "errors": [
    {
      "field": "status",
      "message": "Environment must be stopped to start",
      "code": "invalid_state"
    }
  ],
  "timestamp": "2024-07-24T00:00:00Z",
  "path": "/api/v1/environments/550e8400-e29b-41d4-a716-446655440000/start"
}
```

## Rate Limiting & Security

### Rate Limiting
API implements rate limiting to prevent abuse:

- **Authentication endpoints**: 5 requests per minute per IP
- **General API endpoints**: 100 requests per minute per user
- **WebSocket connections**: 10 concurrent connections per user

Rate limit headers:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1690200000
```

When rate limit is exceeded:
```json
{
  "detail": "Rate limit exceeded. Try again later.",
  "errors": [],
  "timestamp": "2024-07-24T00:00:00Z",
  "retry_after": 60
}
```

### Security Considerations

#### JWT Tokens
- **Access tokens**: 1 hour expiry
- **Refresh tokens**: 7 days expiry
- Tokens are signed with HS256 algorithm
- Include user ID and permissions in payload

#### HTTPS Only
- All API endpoints require HTTPS
- WebSocket connections use WSS (WebSocket Secure)
- HTTP requests are redirected to HTTPS

#### CORS Policy
- CORS enabled for web applications
- Allowed origins configurable per environment
- Credentials included in CORS requests

#### Input Validation
- All inputs validated using Pydantic models
- SQL injection prevention through parameterized queries
- XSS prevention through input sanitization
- File upload restrictions (size, type, content)

#### Environment Isolation
- Each environment runs in isolated containers
- Network policies restrict inter-environment communication
- Resource quotas prevent resource exhaustion
- Automatic cleanup of unused environments

#### Audit Logging
- All API requests logged with user context
- Environment actions tracked for compliance
- Authentication events monitored
- Failed requests analyzed for security patterns

### Best Practices for Integration

#### Authentication
1. Store JWT tokens securely (secure storage on mobile, httpOnly cookies on web)
2. Implement automatic token refresh logic
3. Handle token expiry gracefully
4. Use HTTPS for all requests

#### Error Handling
1. Parse error responses consistently
2. Display user-friendly error messages
3. Implement retry logic for transient errors
4. Log errors for debugging

#### WebSocket Connections
1. Implement connection retry with exponential backoff
2. Handle connection drops gracefully
3. Validate all incoming messages
4. Implement ping/pong for connection health

#### Performance
1. Implement request caching where appropriate
2. Use pagination for large datasets
3. Optimize WebSocket message frequency
4. Implement request deduplication

This comprehensive reference provides all the information needed to integrate with the DevPocket API effectively. For additional support or questions, please refer to the official documentation or contact the development team.