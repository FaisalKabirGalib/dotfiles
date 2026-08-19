# Supabase Profile

Use this profile only when Supabase is an explicit project dependency. Scope Supabase MCP to one project and start with read-only access. Review schema migrations, RLS policies, storage rules, and production data operations before executing them.

Do not add this profile merely because a project uses PostgreSQL; a project-owned PostgreSQL database should use the `postgres` profile instead.
