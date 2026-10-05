-- FASE: Fix RLS para rol ADMIN
-- El problema: las políticas admin en 'profiles' causan recursión infinita
-- porque la política consulta la misma tabla que está siendo protegida.
-- Solución: función SECURITY DEFINER que bypass RLS para verificar rol admin.

-- ============================================================
-- 1. FUNCIÓN is_admin() — bypass RLS con SECURITY DEFINER
-- ============================================================
DROP FUNCTION IF EXISTS public.is_admin();
DROP FUNCTION IF EXISTS public.is_admin(uuid);

CREATE OR REPLACE FUNCTION public.is_admin(check_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = check_user_id AND role = 'ADMIN'
  );
$$;

-- ============================================================
-- 2. PROFILES — admin puede leer y actualizar todos
-- ============================================================
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    auth.uid() = id OR public.is_admin()
  );

CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE USING (
    public.is_admin()
  );

-- ============================================================
-- 3. IDENTITY DOCUMENTS — fix recursión en política admin
-- ============================================================
DROP POLICY IF EXISTS "admin_all_documents" ON identity_documents;

CREATE POLICY "Admins can view all identity documents" ON identity_documents
  FOR SELECT USING (
    auth.uid() = user_id OR public.is_admin()
  );

CREATE POLICY "Admins can update all identity documents" ON identity_documents
  FOR UPDATE USING (
    public.is_admin()
  );

-- ============================================================
-- 4. PLAYERS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage all players" ON players;

CREATE POLICY "Admins can manage all players" ON players
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 5. TEAMS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage all teams" ON teams;

CREATE POLICY "Admins can manage all teams" ON teams
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 6. RESERVATIONS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage all reservations" ON reservations;

CREATE POLICY "Admins can manage all reservations" ON reservations
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 7. PAYMENTS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage all payments" ON payments;

CREATE POLICY "Admins can manage all payments" ON payments
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 8. DISPUTES — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage all disputes" ON disputes;

CREATE POLICY "Admins can manage all disputes" ON disputes
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 9. NOTIFICATIONS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage all notifications" ON notifications;

CREATE POLICY "Admins can manage all notifications" ON notifications
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 10. RATINGS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage all ratings" ON ratings;

CREATE POLICY "Admins can manage all ratings" ON ratings
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 11. QR TOKENS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage all QR tokens" ON qr_tokens;

CREATE POLICY "Admins can manage all QR tokens" ON qr_tokens
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 12. CHECK-INS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage all check-ins" ON check_ins;

CREATE POLICY "Admins can manage all check-ins" ON check_ins
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 13. ADMIN ACTIONS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage admin actions" ON admin_actions;

CREATE POLICY "Admins can manage admin actions" ON admin_actions
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 14. PLATFORM SETTINGS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage platform settings" ON platform_settings;

CREATE POLICY "Admins can manage platform settings" ON platform_settings
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 15. PAYOUTS — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage payouts" ON payouts;

CREATE POLICY "Admins can manage payouts" ON payouts
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 16. PLATFORM FEES — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage platform fees" ON platform_fees;

CREATE POLICY "Admins can manage platform fees" ON platform_fees
  FOR ALL USING (
    public.is_admin()
  );

-- ============================================================
-- 17. DISPUTE EVIDENCE — refrescar política admin con is_admin()
-- ============================================================
DROP POLICY IF EXISTS "Users can view dispute evidence" ON dispute_evidence;

CREATE POLICY "Users can view dispute evidence" ON dispute_evidence
  FOR SELECT USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM disputes d
      JOIN reservations r ON r.id = d.reservation_id
      WHERE d.id = dispute_evidence.dispute_id
      AND (
        EXISTS (SELECT 1 FROM teams t WHERE t.id = r.team_id AND t.user_id = auth.uid())
        OR EXISTS (SELECT 1 FROM players p WHERE p.id = r.player_id AND p.user_id = auth.uid())
      )
    )
  );

-- ============================================================
-- 18. AUDIT LOG — admin puede leer todo
-- ============================================================
DROP POLICY IF EXISTS "Admins can view all audit logs" ON audit_log;

CREATE POLICY "Admins can view all audit logs" ON audit_log
  FOR SELECT USING (
    public.is_admin()
  );
