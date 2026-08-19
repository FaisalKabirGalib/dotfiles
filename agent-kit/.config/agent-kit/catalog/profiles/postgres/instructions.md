# PostgreSQL Profile

Use PostgreSQL as the project's own database through its configured connection string. Do not substitute Neon, Supabase, Vercel Postgres, or another provider unless explicitly requested.

Make schema changes through versioned migrations. Review indexes, constraints, foreign keys, transaction boundaries, and query plans where relevant. Treat migration generation and execution separately; never apply destructive changes or production migrations without confirmation.

Preserve an existing Drizzle or Prisma choice. For a new project, propose one and wait for approval: prefer Drizzle for SQL-first, lightweight, close-to-the-database TypeScript; prefer Prisma when its generated client, declarative schema workflow, and team familiarity are more valuable. Do not install both ORMs.

Use Drizzle Kit or Prisma skills and local MCP tools only when the matching ORM is already part of the project.
