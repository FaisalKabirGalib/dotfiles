# PostgreSQL Profile

Use PostgreSQL as the project's own database through its configured connection string. Do not substitute Neon, Supabase, Vercel Postgres, or another provider unless explicitly requested.

Make schema changes through versioned migrations. Review indexes, constraints, foreign keys, transaction boundaries, and query plans where relevant. Treat migration generation and execution separately; never apply destructive changes or production migrations without confirmation.

Use Drizzle Kit skills and MCP tools only when `drizzle-orm` and `drizzle-kit` are already part of the project.
