-- Supabase Security Hardening Script
-- Enables Row Level Security (RLS) on all tables to satisfy Security Advisor
-- Sets a default "Deny All" policy to prevent direct exposure via PostgREST API

-- 1. Enable RLS on all identified tables
ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."team_projects" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."team_project_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."project_updates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."project_milestones" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."personal_projects" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hackathons" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hackathon_rounds" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."learnings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."daily_activities" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."task_assignments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."task_reports" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."certifications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."ps_skills" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."team_messages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."chat_conversations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."chat_participants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."chat_messages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."system_activities" ENABLE ROW LEVEL SECURITY;

-- 2. Create a "Full Access" policy for the database owner (Prisma)
-- Note: Prisma usually connects as the postgres user which bypasses RLS,
-- but enabling RLS without policies by default denies 'anon' and 'authenticated' roles.
-- No further action is strictly required to satisfy the "RLS Disabled" error,
-- as RLS is now active and defaults to "Deny All" for public/anon roles.

-- 3. Verify RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
