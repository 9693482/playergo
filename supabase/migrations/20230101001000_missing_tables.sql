-- FASE 20: Tablas faltantes - payment_transactions, reviews, reports, cancellation_policies

-- ============================================
-- 1. PAYMENT TRANSACTIONS (historial de transacciones)
-- ============================================
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('charge', 'refund', 'payout', 'fee')),
  amount NUMERIC(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'COP',
  stripe_payment_intent_id TEXT,
  stripe_transfer_id TEXT,
  stripe_charge_id TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'succeeded', 'failed')),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_payment ON payment_transactions(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);

ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "team_own_transactions"
  ON payment_transactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM payments p
      JOIN reservations r ON r.id = p.reservation_id
      WHERE p.id = payment_transactions.payment_id
        AND r.team_id IN (
          SELECT id FROM teams WHERE user_id = auth.uid()
        )
    )
  );

CREATE POLICY "admin_all_transactions"
  ON payment_transactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );

-- ============================================
-- 2. REVIEWS (reseñas escritas, separadas de ratings)
-- ============================================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  reservation_id UUID NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
  rater_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rated_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(reservation_id, rater_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_rated ON reviews(rated_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reservation ON reviews(reservation_id);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_reviews"
  ON reviews FOR SELECT
  USING (is_visible = true);

CREATE POLICY "rater_own_reviews"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = rater_id);

CREATE POLICY "admin_manage_reviews"
  ON reviews FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );

-- ============================================
-- 3. REPORTS (reportes de usuarios/content)
-- ============================================
CREATE TABLE IF NOT EXISTS reports (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reported_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reported_reservation_id UUID REFERENCES reservations(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'resolved', 'dismissed')),
  admin_notes TEXT,
  resolved_by UUID REFERENCES profiles(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reporter_own_reports"
  ON reports FOR SELECT
  USING (auth.uid() = reporter_id);

CREATE POLICY "admin_all_reports"
  ON reports FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );

CREATE POLICY "auth_create_reports"
  ON reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

-- ============================================
-- 4. CANCELLATION POLICIES (políticas de cancelación)
-- ============================================
CREATE TABLE IF NOT EXISTS cancellation_policies (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  hours_before INTEGER NOT NULL,
  refund_percentage NUMERIC(5,2) NOT NULL CHECK (refund_percentage >= 0 AND refund_percentage <= 100),
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE cancellation_policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_policies"
  ON cancellation_policies FOR SELECT
  USING (is_active = true);

CREATE POLICY "admin_manage_policies"
  ON cancellation_policies FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );

INSERT INTO cancellation_policies (name, hours_before, refund_percentage, description) VALUES
  ('Full refund', 48, 100, 'Cancel more than 48 hours before'),
  ('Partial refund 80%', 24, 80, 'Cancel 24-48 hours before'),
  ('Partial refund 50%', 12, 50, 'Cancel 12-24 hours before'),
  ('No refund', 0, 0, 'Cancel less than 12 hours before')
ON CONFLICT DO NOTHING;
