-- Add public read policies for catalog tables
-- Execute this in Supabase SQL Editor

-- Sports: anyone can read
CREATE POLICY "Anyone can view sports" ON sports
  FOR SELECT USING (true);

-- Positions: anyone can read
CREATE POLICY "Anyone can view positions" ON positions
  FOR SELECT USING (true);

-- Countries: anyone can read
CREATE POLICY "Anyone can view countries" ON countries
  FOR SELECT USING (true);

-- Regions: anyone can read
CREATE POLICY "Anyone can view regions" ON regions
  FOR SELECT USING (true);

-- Cities: anyone can read
CREATE POLICY "Anyone can view cities" ON cities
  FOR SELECT USING (true);

-- Venues: anyone can read
CREATE POLICY "Anyone can view venues" ON venues
  FOR SELECT USING (true);

-- Player availability: anyone can read
CREATE POLICY "Anyone can view availability" ON player_availability
  FOR SELECT USING (true);

-- Player blocked dates: players can manage own
CREATE POLICY "Players can manage own blocked dates" ON player_blocked_dates
  FOR ALL USING (
    EXISTS (SELECT 1 FROM players WHERE id = player_blocked_dates.player_id AND user_id = auth.uid())
  );

-- Favorites: users can manage own
CREATE POLICY "Users can view own favorites" ON favorites
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own favorites" ON favorites
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM teams WHERE id = favorites.team_id AND user_id = auth.uid())
  );

CREATE POLICY "Users can delete own favorites" ON favorites
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM teams WHERE id = favorites.team_id AND user_id = auth.uid())
  );

-- Reservations: team can insert
CREATE POLICY "Teams can create reservations" ON reservations
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM teams WHERE id = reservations.team_id AND user_id = auth.uid())
  );

-- Reservations: player can update status
CREATE POLICY "Players can update reservation status" ON reservations
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM players WHERE id = reservations.player_id AND user_id = auth.uid())
  );

-- Payments: team can view own
CREATE POLICY "Teams can view own payments" ON payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN teams t ON t.id = r.team_id
      WHERE r.id = payments.reservation_id AND t.user_id = auth.uid()
    )
  );

-- QR tokens: team can view for their reservations
CREATE POLICY "Team can view QR for reservations" ON qr_tokens
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN teams t ON t.id = r.team_id
      WHERE r.id = qr_tokens.reservation_id AND t.user_id = auth.uid()
    )
  );

-- QR tokens: player can view for their reservations
CREATE POLICY "Player can view QR for reservations" ON qr_tokens
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN players p ON p.id = r.player_id
      WHERE r.id = qr_tokens.reservation_id AND p.user_id = auth.uid()
    )
  );

-- Ratings: anyone can read
CREATE POLICY "Anyone can view ratings" ON ratings
  FOR SELECT USING (true);

-- Ratings: participants can insert
CREATE POLICY "Participants can insert ratings" ON ratings
  FOR INSERT WITH CHECK (
    auth.uid() = rater_id
  );
