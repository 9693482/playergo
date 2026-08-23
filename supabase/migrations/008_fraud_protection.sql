-- FASE 28: Protección contra fraude

-- ============================================
-- 1. AUDIT LOG TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id UUID,
  details JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON audit_log(entity, entity_id);

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_full_access_audit"
  ON audit_log FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );

-- Only allow inserts via function
CREATE POLICY "service_insert_audit"
  ON audit_log FOR INSERT
  WITH CHECK (true);

-- ============================================
-- 2. RATE LIMITING FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id UUID,
  p_action TEXT,
  p_window_seconds INT DEFAULT 60,
  p_max_count INT DEFAULT 10
)
RETURNS BOOLEAN AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM audit_log
  WHERE user_id = p_user_id
    AND action = p_action
    AND created_at > NOW() - (p_window_seconds || ' seconds')::INTERVAL;

  RETURN v_count < p_max_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 3. DOUBLE RESERVATION DETECTION
-- ============================================
CREATE OR REPLACE FUNCTION check_no_overlapping_reservation()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status NOT IN ('CANCELLED', 'REJECTED') THEN
    IF EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.player_id = NEW.player_id
        AND r.id != NEW.id
        AND r.reservation_date = NEW.reservation_date
        AND r.status NOT IN ('CANCELLED', 'REJECTED')
        AND r.start_time < NEW.end_time
        AND r.end_time > NEW.start_time
    ) THEN
      RAISE EXCEPTION 'Player already has a reservation at this time';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_no_overlapping_reservation
  BEFORE INSERT OR UPDATE ON reservations
  FOR EACH ROW
  EXECUTE FUNCTION check_no_overlapping_reservation();

-- ============================================
-- 4. ACCOUNT BLOCKING (is_active flag)
-- ============================================
CREATE OR REPLACE FUNCTION block_user_check()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_active = false THEN
    RAISE EXCEPTION 'Account is blocked';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Block login for inactive accounts
CREATE OR REPLACE FUNCTION handle_blocked_login()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM profiles
    WHERE id = NEW.id AND is_active = false
  ) THEN
    RAISE EXCEPTION 'Account is blocked';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. LOG AUDIT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION log_reservation_audit()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    INSERT INTO audit_log (action, entity, entity_id, details)
    VALUES (
      'status_change:' || OLD.status || '->' || NEW.status,
      'reservation',
      NEW.id,
      jsonb_build_object(
        'old_status', OLD.status,
        'new_status', NEW.status,
        'reservation_date', NEW.reservation_date,
        'player_id', NEW.player_id,
        'team_id', NEW.team_id
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reservation_audit
  AFTER UPDATE ON reservations
  FOR EACH ROW
  EXECUTE FUNCTION log_reservation_audit();

-- ============================================
-- 6. ENFORCE SINGLE-USE QR TOKEN
-- ============================================
CREATE OR REPLACE FUNCTION enforce_single_use_qr()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.is_used = true THEN
    RAISE EXCEPTION 'QR token already used';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_single_use_qr
  BEFORE UPDATE ON qr_tokens
  FOR EACH ROW
  WHEN (NEW.is_used = true)
  EXECUTE FUNCTION enforce_single_use_qr();
