# Go Profile

Follow standard Go layout and tooling: format with `gofmt`, run `go vet` and focused `go test` commands, propagate contexts, wrap errors with useful context, and avoid unnecessary abstractions. Prefer the repository's established router, logger, database driver, and dependency-injection pattern.

Use database, container, cloud, and MCP tooling only when the project already uses those services. For Genkit projects, use the official Genkit Go skill; otherwise keep language guidance local to the repository.
