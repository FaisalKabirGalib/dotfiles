# Next.js Profile

Use TypeScript, App Router conventions, Server Components by default, and explicit client boundaries only where browser APIs or interactivity require them. Follow the project's package manager, linting, and test setup.

Use PostgreSQL owned by the project through `DATABASE_URL`; do not introduce Neon, Vercel Postgres, Supabase, or another hosted database without an explicit request. Preserve the repository's ORM when it already uses Drizzle or Prisma. For a new project, recommend one ORM based on its needs and ask for confirmation before adding it; never add both. Keep schema changes as reviewed migrations and never apply a destructive migration without confirmation.

Deploy with the repository's container workflow. Keep Dockerfiles small, reproducible, and production-oriented; do not add a Vercel deployment path unless asked. When UI changes are made, include the `web-design` profile and verify responsive behavior with the configured browser tool.
