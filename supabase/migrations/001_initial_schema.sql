-- PlayerGo Database Schema
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ENUMS
-- ============================================

CREATE TYPE user_role AS ENUM ('PLAYER', 'TEAM', 'ADMIN');
CREATE TYPE verification_status AS ENUM ('UNVERIFIED', 'PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED');
CREATE TYPE reservation_status AS ENUM (
  'PENDING', 'ACCEPTED', 'REJECTED', 'PAYMENT_PENDING',
  'PAID', 'CONFIRMED', 'ARRIVED', 'COMPLETED',
  'CANCELLED', 'DISPUTED', 'REFUNDED'
);
CREATE TYPE dispute_status AS ENUM ('OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED', 'REFUNDED');
CREATE TYPE payment_status AS ENUM ('PENDING', 'SUCCEEDED', 'FAILED', 'REFUNDED');
CREATE TYPE payout_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');

-- ============================================
-- COUNTRIES, REGIONS, CITIES
-- ============================================

CREATE TABLE countries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  currency TEXT NOT NULL,
  currency_symbol TEXT NOT NULL,
  currency_locale TEXT,
  phone_code TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE regions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  country_id UUID NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  region_id UUID NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SPORTS AND POSITIONS
-- ============================================

CREATE TABLE sports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sport_id UUID NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(sport_id, slug)
);

-- ============================================
-- VENUES (CANCHAS)
-- ============================================

CREATE TABLE venues (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  city_id UUID NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  phone TEXT,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PROFILES (USERS)
-- ============================================

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  phone TEXT,
  role user_role NOT NULL DEFAULT 'PLAYER',
  photo_url TEXT,
  verification_status verification_status DEFAULT 'UNVERIFIED',
  country_id UUID REFERENCES countries(id),
  region_id UUID REFERENCES regions(id),
  city_id UUID REFERENCES cities(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PLAYERS
-- ============================================

CREATE TABLE players (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  sport_id UUID NOT NULL REFERENCES sports(id),
  position_id UUID NOT NULL REFERENCES positions(id),
  bio TEXT,
  experience_years INTEGER DEFAULT 0,
  price_per_match DECIMAL(10, 2) NOT NULL,
  rating DECIMAL(3, 2) DEFAULT 0,
  completed_matches INTEGER DEFAULT 0,
  availability_status BOOLEAN DEFAULT true,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, sport_id, position_id)
);

-- ============================================
-- TEAMS
-- ============================================

CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  team_name TEXT NOT NULL,
  logo_url TEXT,
  sport_id UUID REFERENCES sports(id),
  description TEXT,
  captain_name TEXT,
  captain_phone TEXT,
  rating DECIMAL(3, 2) DEFAULT 0,
  completed_matches INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PLAYER AVAILABILITY
-- ============================================

CREATE TABLE player_availability (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(player_id, day_of_week)
);

CREATE TABLE player_blocked_dates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  blocked_date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(player_id, blocked_date, start_time)
);

-- ============================================
-- RESERVATIONS
-- ============================================

CREATE TABLE reservations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID NOT NULL REFERENCES teams(id),
  player_id UUID NOT NULL REFERENCES players(id),
  venue_id UUID REFERENCES venues(id),
  sport_id UUID NOT NULL REFERENCES sports(id),
  position_id UUID NOT NULL REFERENCES positions(id),
  reservation_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  duration_hours DECIMAL(3, 1) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  status reservation_status DEFAULT 'PENDING',
  notes TEXT,
  cancellation_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reservation_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reservation_id UUID NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
  old_status reservation_status,
  new_status reservation_status NOT NULL,
  changed_by UUID REFERENCES profiles(id),
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PAYMENTS
-- ============================================

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reservation_id UUID NOT NULL REFERENCES reservations(id),
  stripe_payment_intent_id TEXT,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT NOT NULL,
  status payment_status DEFAULT 'PENDING',
  platform_fee DECIMAL(10, 2),
  provider_amount DECIMAL(10, 2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  player_id UUID NOT NULL REFERENCES players(id),
  payment_id UUID NOT NULL REFERENCES payments(id),
  stripe_transfer_id TEXT,
  amount DECIMAL(10, 2) NOT NULL,
  status payout_status DEFAULT 'PENDING',
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE platform_fees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_id UUID NOT NULL REFERENCES payments(id),
  amount DECIMAL(10, 2) NOT NULL,
  percentage DECIMAL(5, 2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- QR TOKENS & CHECK-INS
-- ============================================

CREATE TABLE qr_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reservation_id UUID NOT NULL REFERENCES reservations(id),
  token TEXT NOT NULL UNIQUE,
  signature TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_used BOOLEAN DEFAULT false,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE check_ins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reservation_id UUID NOT NULL REFERENCES reservations(id),
  qr_token_id UUID NOT NULL REFERENCES qr_tokens(id),
  player_id UUID NOT NULL REFERENCES players(id),
  team_id UUID NOT NULL REFERENCES teams(id),
  device_id TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  checked_in_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- RATINGS
-- ============================================

CREATE TABLE ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reservation_id UUID NOT NULL REFERENCES reservations(id),
  rater_id UUID NOT NULL REFERENCES profiles(id),
  rated_id UUID NOT NULL REFERENCES profiles(id),
  score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  punctuality INTEGER CHECK (punctuality BETWEEN 1 AND 5),
  behavior INTEGER CHECK (behavior BETWEEN 1 AND 5),
  skill_level INTEGER CHECK (skill_level BETWEEN 1 AND 5),
  compliance INTEGER CHECK (compliance BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(reservation_id, rater_id)
);

-- ============================================
-- FAVORITES
-- ============================================

CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, player_id)
);

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- DISPUTES
-- ============================================

CREATE TABLE disputes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reservation_id UUID NOT NULL REFERENCES reservations(id),
  opened_by UUID NOT NULL REFERENCES profiles(id),
  reason TEXT NOT NULL,
  description TEXT,
  status dispute_status DEFAULT 'OPEN',
  resolution TEXT,
  resolved_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE TABLE dispute_evidence (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dispute_id UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type TEXT,
  description TEXT,
  uploaded_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PLATFORM SETTINGS
-- ============================================

CREATE TABLE platform_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT NOT NULL UNIQUE,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings
INSERT INTO platform_settings (key, value, description) VALUES
  ('platform_fee_percentage', '15', 'Platform commission percentage'),
  ('minimum_service_price', '20000', 'Minimum service price'),
  ('maximum_service_price', '500000', 'Maximum service price'),
  ('currency', 'COP', 'Default currency'),
  ('cancellation_before_24h', '100', 'Refund percentage for cancellation >24h'),
  ('cancellation_12_24h', '80', 'Refund percentage for cancellation 12-24h'),
  ('cancellation_less_12h', '50', 'Refund percentage for cancellation <12h'),
  ('no_show_penalty', '100', 'Penalty percentage for no show');

-- ============================================
-- ADMIN ACTIONS
-- ============================================

CREATE TABLE admin_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES profiles(id),
  target_user_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_city ON profiles(city_id);
CREATE INDEX idx_players_user ON players(user_id);
CREATE INDEX idx_players_sport ON players(sport_id);
CREATE INDEX idx_players_position ON players(position_id);
CREATE INDEX idx_players_city ON players(latitude, longitude);
CREATE INDEX idx_teams_user ON teams(user_id);
CREATE INDEX idx_reservations_team ON reservations(team_id);
CREATE INDEX idx_reservations_player ON reservations(player_id);
CREATE INDEX idx_reservations_date ON reservations(reservation_date);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_payments_reservation ON payments(reservation_id);
CREATE INDEX idx_qr_tokens_reservation ON qr_tokens(reservation_id);
CREATE INDEX idx_qr_tokens_token ON qr_tokens(token);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_disputes_reservation ON disputes(reservation_id);

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read/update their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- Players: Public read, own write
CREATE POLICY "Anyone can view players" ON players
  FOR SELECT USING (true);

CREATE POLICY "Players can update own data" ON players
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND id = players.user_id)
  );

-- Teams: Public read, own write
CREATE POLICY "Anyone can view teams" ON teams
  FOR SELECT USING (true);

CREATE POLICY "Teams can update own data" ON teams
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND id = teams.user_id)
  );

-- Reservations: Team and Player can view their own
CREATE POLICY "Team can view own reservations" ON reservations
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM teams WHERE id = reservations.team_id AND user_id = auth.uid())
  );

CREATE POLICY "Player can view own reservations" ON reservations
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM players WHERE id = reservations.player_id AND user_id = auth.uid())
  );

-- Notifications: Own only
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);
