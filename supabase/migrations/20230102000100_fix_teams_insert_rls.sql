-- Fix: allow authenticated users to INSERT their first team.
-- The existing "Teams can manage own data" FOR ALL USING requires the team
-- to already exist, blocking INSERT. Split into INSERT (WITH CHECK on user_id)
-- and UPDATE/DELETE (USING on user_id).

DROP POLICY IF EXISTS "Teams can manage own data" ON teams;
DROP POLICY IF EXISTS "Teams can update own data" ON teams;
DROP POLICY IF EXISTS "Teams can delete own data" ON teams;

CREATE POLICY "Teams can insert own team" ON teams
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Teams can update own data" ON teams
  FOR UPDATE USING (
    auth.uid() = user_id
  );

CREATE POLICY "Teams can delete own data" ON teams
  FOR DELETE USING (
    auth.uid() = user_id
  );
