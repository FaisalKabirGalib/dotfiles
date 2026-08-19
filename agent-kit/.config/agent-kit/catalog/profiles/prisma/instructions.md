# Prisma Profile

Use Prisma only when the repository already uses it or it has been selected for the project. Connect to the project's own PostgreSQL instance through `DATABASE_URL`; do not replace it with Prisma Postgres or another hosted provider.

Use the local `prisma mcp` and Prisma Skills for schema, client, and migration guidance. Keep generated migrations reviewed, separate generation from application, and never run reset, destructive migration, or production data operations without explicit confirmation.
