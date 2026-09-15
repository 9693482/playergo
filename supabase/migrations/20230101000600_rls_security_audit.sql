-- FASE 22: SEGURIDAD - RLS Audit & Fix
-- Drop all existing policies and recreate with proper role-based access

-- ============================================================
-- PROFILES (no admin policies here - causes recursion)
-- ============================================================
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Anyone can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================================
-- PLAYERS
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view players" ON players;
DROP POLICY IF EXISTS "Players can manage own data" ON players;
DROP POLICY IF EXISTS "Admins can manage all players" ON players;

CREATE POLICY "Anyone can view players" ON players
  FOR SELECT USING (true);

CREATE POLICY "Players can manage own data" ON players
  FOR ALL USING (
    EXISTS (SELECT 1 FROM players WHERE players.user_id = auth.uid())
  );

CREATE POLICY "Admins can manage all players" ON players
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- TEAMS
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view teams" ON teams;
DROP POLICY IF EXISTS "Teams can manage own data" ON teams;
DROP POLICY IF EXISTS "Admins can manage all teams" ON teams;

CREATE POLICY "Anyone can view teams" ON teams
  FOR SELECT USING (true);

CREATE POLICY "Teams can manage own data" ON teams
  FOR ALL USING (
    EXISTS (SELECT 1 FROM teams WHERE teams.user_id = auth.uid())
  );

CREATE POLICY "Admins can manage all teams" ON teams
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- CATALOG TABLES (public read)
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view sports" ON sports;
CREATE POLICY "Anyone can view sports" ON sports FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can view positions" ON positions;
CREATE POLICY "Anyone can view positions" ON positions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can view countries" ON countries;
CREATE POLICY "Anyone can view countries" ON countries FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can view regions" ON regions;
CREATE POLICY "Anyone can view regions" ON regions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can view cities" ON cities;
CREATE POLICY "Anyone can view cities" ON cities FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can view venues" ON venues;
CREATE POLICY "Anyone can view venues" ON venues FOR SELECT USING (true);

-- ============================================================
-- PLAYER AVAILABILITY
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view availability" ON player_availability;
DROP POLICY IF EXISTS "Players can manage own availability" ON player_availability;

CREATE POLICY "Anyone can view availability" ON player_availability
  FOR SELECT USING (true);

CREATE POLICY "Players can manage own availability" ON player_availability
  FOR ALL USING (
    EXISTS (SELECT 1 FROM players WHERE players.id = player_availability.player_id AND players.user_id = auth.uid())
  );

-- ============================================================
-- PLAYER BLOCKED DATES
-- ============================================================
DROP POLICY IF EXISTS "Players can manage own blocked dates" ON player_blocked_dates;

CREATE POLICY "Players can manage own blocked dates" ON player_blocked_dates
  FOR ALL USING (
    EXISTS (SELECT 1 FROM players WHERE players.id = player_blocked_dates.player_id AND players.user_id = auth.uid())
  );

-- ============================================================
-- RESERVATIONS
-- ============================================================
DROP POLICY IF EXISTS "Teams can create reservations" ON reservations;
DROP POLICY IF EXISTS "Players can update reservation status" ON reservations;
DROP POLICY IF EXISTS "Teams can view own reservations" ON reservations;
DROP POLICY IF EXISTS "Players can view own reservations" ON reservations;
DROP POLICY IF EXISTS "Admins can manage all reservations" ON reservations;

CREATE POLICY "Teams can create reservations" ON reservations
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM teams WHERE teams.id = reservations.team_id AND teams.user_id = auth.uid())
  );

CREATE POLICY "Teams can view own reservations" ON reservations
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM teams WHERE teams.id = reservations.team_id AND teams.user_id = auth.uid())
  );

CREATE POLICY "Players can view own reservations" ON reservations
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM players WHERE players.id = reservations.player_id AND players.user_id = auth.uid())
  );

CREATE POLICY "Players can update reservation status" ON reservations
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM players WHERE players.id = reservations.player_id AND players.user_id = auth.uid())
  );

CREATE POLICY "Teams can update own reservations" ON reservations
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM teams WHERE teams.id = reservations.team_id AND teams.user_id = auth.uid())
  );

CREATE POLICY "Admins can manage all reservations" ON reservations
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- RESERVATION STATUS HISTORY
-- ============================================================
DROP POLICY IF EXISTS "Users can view reservation history" ON reservation_status_history;

CREATE POLICY "Users can view reservation history" ON reservation_status_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = reservation_status_history.reservation_id
      AND (
        EXISTS (SELECT 1 FROM teams t WHERE t.id = r.team_id AND t.user_id = auth.uid())
        OR EXISTS (SELECT 1 FROM players p WHERE p.id = r.player_id AND p.user_id = auth.uid())
      )
    )
  );

-- ============================================================
-- PAYMENTS
-- ============================================================
DROP POLICY IF EXISTS "Teams can view own payments" ON payments;
DROP POLICY IF EXISTS "Admins can manage all payments" ON payments;

CREATE POLICY "Teams can view own payments" ON payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN teams t ON t.id = r.team_id
      WHERE r.id = payments.reservation_id AND t.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all payments" ON payments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- PAYOUTS
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage payouts" ON payouts;

CREATE POLICY "Admins can manage payouts" ON payouts
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- PLATFORM FEES
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage platform fees" ON platform_fees;

CREATE POLICY "Admins can manage platform fees" ON platform_fees
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- QR TOKENS
-- ============================================================
DROP POLICY IF EXISTS "Team can view QR for reservations" ON qr_tokens;
DROP POLICY IF EXISTS "Player can view QR for reservations" ON qr_tokens;
DROP POLICY IF EXISTS "Teams can create QR tokens" ON qr_tokens;
DROP POLICY IF EXISTS "Admins can manage all QR tokens" ON qr_tokens;

CREATE POLICY "Teams can create QR tokens" ON qr_tokens
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN teams t ON t.id = r.team_id
      WHERE r.id = qr_tokens.reservation_id AND t.user_id = auth.uid()
    )
  );

CREATE POLICY "Team can view QR for reservations" ON qr_tokens
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN teams t ON t.id = r.team_id
      WHERE r.id = qr_tokens.reservation_id AND t.user_id = auth.uid()
    )
  );

CREATE POLICY "Player can view QR for reservations" ON qr_tokens
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN players p ON p.id = r.player_id
      WHERE r.id = qr_tokens.reservation_id AND p.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all QR tokens" ON qr_tokens
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- CHECK-INS
-- ============================================================
DROP POLICY IF EXISTS "Users can view own check-ins" ON check_ins;
DROP POLICY IF EXISTS "Admins can manage all check-ins" ON check_ins;

CREATE POLICY "Users can view own check-ins" ON check_ins
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = check_ins.reservation_id
      AND (
        EXISTS (SELECT 1 FROM teams t WHERE t.id = r.team_id AND t.user_id = auth.uid())
        OR EXISTS (SELECT 1 FROM players p WHERE p.id = r.player_id AND p.user_id = auth.uid())
      )
    )
  );

CREATE POLICY "Admins can manage all check-ins" ON check_ins
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- RATINGS
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view ratings" ON ratings;
DROP POLICY IF EXISTS "Participants can insert ratings" ON ratings;
DROP POLICY IF EXISTS "Admins can manage all ratings" ON ratings;

CREATE POLICY "Anyone can view ratings" ON ratings
  FOR SELECT USING (true);

CREATE POLICY "Participants can insert ratings" ON ratings
  FOR INSERT WITH CHECK (auth.uid() = rater_id);

CREATE POLICY "Users can view own ratings" ON ratings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = ratings.reservation_id
      AND (
        EXISTS (SELECT 1 FROM teams t WHERE t.id = r.team_id AND t.user_id = auth.uid())
        OR EXISTS (SELECT 1 FROM players p WHERE p.id = r.player_id AND p.user_id = auth.uid())
      )
    )
  );

CREATE POLICY "Admins can manage all ratings" ON ratings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- FAVORITES
-- ============================================================
DROP POLICY IF EXISTS "Users can view own favorites" ON favorites;
DROP POLICY IF EXISTS "Users can insert own favorites" ON favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON favorites;

CREATE POLICY "Users can view own favorites" ON favorites
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM teams WHERE teams.id = favorites.team_id AND teams.user_id = auth.uid())
  );

CREATE POLICY "Users can insert own favorites" ON favorites
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM teams WHERE teams.id = favorites.team_id AND teams.user_id = auth.uid())
  );

CREATE POLICY "Users can delete own favorites" ON favorites
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM teams WHERE teams.id = favorites.team_id AND teams.user_id = auth.uid())
  );

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;

CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage all notifications" ON notifications
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- DISPUTES
-- ============================================================
DROP POLICY IF EXISTS "Users can view own disputes" ON disputes;
DROP POLICY IF EXISTS "Users can create disputes" ON disputes;
DROP POLICY IF EXISTS "Users can update own disputes" ON disputes;
DROP POLICY IF EXISTS "Admins can manage all disputes" ON disputes;

CREATE POLICY "Users can view own disputes" ON disputes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = disputes.reservation_id
      AND (
        EXISTS (SELECT 1 FROM teams t WHERE t.id = r.team_id AND t.user_id = auth.uid())
        OR EXISTS (SELECT 1 FROM players p WHERE p.id = r.player_id AND p.user_id = auth.uid())
      )
    )
  );

CREATE POLICY "Users can create disputes" ON disputes
  FOR INSERT WITH CHECK (auth.uid() = opened_by);

CREATE POLICY "Users can update own disputes" ON disputes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = disputes.reservation_id
      AND (
        EXISTS (SELECT 1 FROM teams t WHERE t.id = r.team_id AND t.user_id = auth.uid())
        OR EXISTS (SELECT 1 FROM players p WHERE p.id = r.player_id AND p.user_id = auth.uid())
      )
    )
  );

CREATE POLICY "Admins can manage all disputes" ON disputes
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- DISPUTE EVIDENCE
-- ============================================================
DROP POLICY IF EXISTS "Users can view dispute evidence" ON dispute_evidence;

CREATE POLICY "Users can view dispute evidence" ON dispute_evidence
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM disputes d
      JOIN reservations r ON r.id = d.reservation_id
      WHERE d.id = dispute_evidence.dispute_id
      AND (
        EXISTS (SELECT 1 FROM teams t WHERE t.id = r.team_id AND t.user_id = auth.uid())
        OR EXISTS (SELECT 1 FROM players p WHERE p.id = r.player_id AND p.user_id = auth.uid())
      )
    )
  );

CREATE POLICY "Users can insert dispute evidence" ON dispute_evidence
  FOR INSERT WITH CHECK (auth.uid() = uploaded_by);

-- ============================================================
-- PLATFORM SETTINGS
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view platform settings" ON platform_settings;
DROP POLICY IF EXISTS "Admins can manage platform settings" ON platform_settings;

CREATE POLICY "Anyone can view platform settings" ON platform_settings
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage platform settings" ON platform_settings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- ADMIN ACTIONS
-- ============================================================
DROP POLICY IF EXISTS "Admins can manage admin actions" ON admin_actions;

CREATE POLICY "Admins can manage admin actions" ON admin_actions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- ============================================================
-- FCM TOKENS
-- ============================================================
DROP POLICY IF EXISTS "Users can manage own FCM tokens" ON fcm_tokens;

CREATE POLICY "Users can manage own FCM tokens" ON fcm_tokens
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- CHATS
-- ============================================================
DROP POLICY IF EXISTS "Users can view own chats" ON chats;
DROP POLICY IF EXISTS "Users can create chats" ON chats;

CREATE POLICY "Users can view own chats" ON chats
  FOR SELECT USING (
    auth.uid() = player_id OR auth.uid() = team_id
  );

CREATE POLICY "Users can create chats" ON chats
  FOR INSERT WITH CHECK (
    auth.uid() = player_id OR auth.uid() = team_id
  );

-- ============================================================
-- MESSAGES
-- ============================================================
DROP POLICY IF EXISTS "Users can view chat messages" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update messages" ON messages;

CREATE POLICY "Users can view chat messages" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chats c
      WHERE c.id = messages.chat_id
      AND (auth.uid() = c.player_id OR auth.uid() = c.team_id)
    )
  );

CREATE POLICY "Users can send messages" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM chats c
      WHERE c.id = messages.chat_id
      AND (auth.uid() = c.player_id OR auth.uid() = c.team_id)
    )
  );

CREATE POLICY "Users can update own messages" ON messages
  FOR UPDATE USING (auth.uid() = sender_id);
