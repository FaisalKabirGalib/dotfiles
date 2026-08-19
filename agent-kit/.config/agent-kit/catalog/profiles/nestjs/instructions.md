# NestJS Profile

Preserve Nest module boundaries and use dependency injection, DTO validation, guards, interceptors, and exception filters consistently with the existing application. Keep controllers thin and place business logic in services or domain modules.

Document externally consumed endpoints with the project's OpenAPI approach, test both unit and integration boundaries, and use the `postgres`, `drizzle`, `prisma`, and `docker` profiles only when those technologies exist in the repository. Do not add both Drizzle and Prisma.
