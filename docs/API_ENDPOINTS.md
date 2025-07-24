# DevPocket API Endpoints

## Overview
This document lists all available API endpoints in the DevPocket server.

## Authentication
Most endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

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

## Environment Management API

### POST /api/v1/environments/{environment_id}/restart
Restart an environment
- **Authentication:** Required
- **Returns:** Success message
- **Note:** Environment must be in running, stopped, or error state

### GET /api/v1/environments/{environment_id}/logs
Get environment logs
- **Query Parameters:**
  - `lines`: Number of log lines to retrieve (1-1000, default: 100)
  - `since`: Get logs since timestamp (ISO format, e.g., 2024-01-01T12:00:00Z)
- **Authentication:** Required
- **Returns:** Log entries with metadata

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
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden (Admin required)
- `404`: Not Found
- `422`: Validation Error
- `500`: Internal Server Error