---
name: api-design
description: Expert guidance on RESTful API design, endpoint structure, error handling, and API documentation. Activates when working on API routes, controllers, or backend endpoints.
version: 1.0.0
---

# API Design Expert

Provide expert guidance on designing well-structured, maintainable APIs.

## RESTful Principles

- **Resource-based URLs**: `/users/{id}` not `/getUsers`
- **HTTP methods**: GET (read), POST (create), PUT/PATCH (update), DELETE (delete)
- **Status codes**: 200 (success), 201 (created), 400 (bad request), 404 (not found), 500 (server error)
- **Stateless**: Each request contains all necessary information

## Best Practices

- Version your APIs: `/api/v1/...`
- Use pagination for list endpoints
- Implement rate limiting
- Document with OpenAPI/Swagger
- Validate all input
