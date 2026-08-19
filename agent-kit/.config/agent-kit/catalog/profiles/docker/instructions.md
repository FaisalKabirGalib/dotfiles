# Docker Profile

Use this profile only when the repository contains a `Dockerfile`, Compose file, or `.devcontainer` configuration. Preserve the existing container strategy and use the repository's documented build, test, and deployment commands.

Prefer multi-stage builds, pinned base-image major versions, a non-root runtime user where practical, explicit environment configuration, and `.dockerignore`. Do not expose secrets in images, Dockerfiles, Compose files, or build logs.

Docker MCP Toolkit is optional and only applies to a local Docker Desktop installation. Do not require it for standard Docker Engine or Compose workflows.
