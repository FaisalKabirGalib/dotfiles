# Rust Profile

Follow the workspace's edition, clippy configuration, error-handling style, and crate boundaries. Run `cargo fmt`, focused `cargo test`, and `cargo clippy` where relevant. Prefer explicit ownership and error propagation over unnecessary cloning, panics, or unsafe code.

Use Docker, database, cloud, fuzzing, and security tooling only when the project calls for it. For security-sensitive changes, add a focused review and test plan rather than a generic Rust MCP server.
