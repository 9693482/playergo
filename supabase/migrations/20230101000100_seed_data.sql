-- PlayerGo Seed Data
-- Run this after the initial schema

-- ============================================
-- SPORTS
-- ============================================

INSERT INTO sports (name, slug) VALUES
  ('Fútbol', 'football'),
  ('Baloncesto', 'basketball'),
  ('Voleibol', 'volleyball'),
  ('Futsal', 'futsal');

-- ============================================
-- POSITIONS - Fútbol
-- ============================================

INSERT INTO positions (sport_id, name, slug) VALUES
  ((SELECT id FROM sports WHERE slug = 'football'), 'Arquero', 'goalkeeper'),
  ((SELECT id FROM sports WHERE slug = 'football'), 'Defensa', 'defender'),
  ((SELECT id FROM sports WHERE slug = 'football'), 'Mediocampista', 'midfielder'),
  ((SELECT id FROM sports WHERE slug = 'football'), 'Delantero', 'forward');

-- ============================================
-- POSITIONS - Baloncesto
-- ============================================

INSERT INTO positions (sport_id, name, slug) VALUES
  ((SELECT id FROM sports WHERE slug = 'basketball'), 'Base', 'point_guard'),
  ((SELECT id FROM sports WHERE slug = 'basketball'), 'Escolta', 'shooting_guard'),
  ((SELECT id FROM sports WHERE slug = 'basketball'), 'Alero', 'small_forward'),
  ((SELECT id FROM sports WHERE slug = 'basketball'), 'Ala-Pívot', 'power_forward'),
  ((SELECT id FROM sports WHERE slug = 'basketball'), 'Pívot', 'center');

-- ============================================
-- POSITIONS - Voleibol
-- ============================================

INSERT INTO positions (sport_id, name, slug) VALUES
  ((SELECT id FROM sports WHERE slug = 'volleyball'), 'Saqueador', 'server'),
  ((SELECT id FROM sports WHERE slug = 'volleyball'), 'Receptor', 'receiver'),
  ((SELECT id FROM sports WHERE slug = 'volleyball'), 'Colocador', 'setter'),
  ((SELECT id FROM sports WHERE slug = 'volleyball'), 'Central', 'middle_blocker'),
  ((SELECT id FROM sports WHERE slug = 'volleyball'), 'Opuesto', 'opposite'),
  ((SELECT id FROM sports WHERE slug = 'volleyball'), 'Líbero', 'libero');

-- ============================================
-- POSITIONS - Futsal
-- ============================================

INSERT INTO positions (sport_id, name, slug) VALUES
  ((SELECT id FROM sports WHERE slug = 'futsal'), 'Arquero', 'goalkeeper'),
  ((SELECT id FROM sports WHERE slug = 'futsal'), 'Cierre', 'fixo'),
  ((SELECT id FROM sports WHERE slug = 'futsal'), 'Ala', 'ala'),
  ((SELECT id FROM sports WHERE slug = 'futsal'), 'Pívot', 'pivot');

-- ============================================
-- COUNTRIES
-- ============================================

INSERT INTO countries (name, code, currency, currency_symbol, currency_locale, phone_code) VALUES
  ('Colombia', 'CO', 'COP', '$', 'es-CO', '+57'),
  ('Estados Unidos', 'US', 'USD', '$', 'en-US', '+1'),
  ('España', 'ES', 'EUR', '€', 'es-ES', '+34'),
  ('México', 'MX', 'MXN', '$', 'es-MX', '+52'),
  ('Brasil', 'BR', 'BRL', 'R$', 'pt-BR', '+55');

-- ============================================
-- REGIONS - Colombia
-- ============================================

INSERT INTO regions (country_id, name, code) VALUES
  ((SELECT id FROM countries WHERE code = 'CO'), 'Santander', 'SAN'),
  ((SELECT id FROM countries WHERE code = 'CO'), 'Bogotá D.C.', 'BOG'),
  ((SELECT id FROM countries WHERE code = 'CO'), 'Antioquia', 'ANT'),
  ((SELECT id FROM countries WHERE code = 'CO'), 'Valle del Cauca', 'VAC');

-- ============================================
-- CITIES - Santander
-- ============================================

INSERT INTO cities (region_id, name, latitude, longitude) VALUES
  ((SELECT id FROM regions WHERE code = 'SAN'), 'Bucaramanga', 7.1254, -73.1198),
  ((SELECT id FROM regions WHERE code = 'SAN'), 'Floridablanca', 7.0643, -73.0944),
  ((SELECT id FROM regions WHERE code = 'SAN'), 'Barrancabermeja', 7.0653, -73.8555),
  ((SELECT id FROM regions WHERE code = 'SAN'), 'Girón', 7.0688, -73.1661);

-- ============================================
-- VENUES - Bucaramanga
-- ============================================

INSERT INTO venues (city_id, name, address, latitude, longitude) VALUES
  ((SELECT id FROM cities WHERE name = 'Bucaramanga'), 'Cancha Elite', 'Cra 15 #32-18', 7.1210, -73.1210),
  ((SELECT id FROM cities WHERE name = 'Bucaramanga'), 'Cancha La 21', 'Cra 21 #45-12', 7.1250, -73.1180),
  ((SELECT id FROM cities WHERE name = 'Bucaramanga'), 'Polideportivo UIS', 'Cra 27 #9-50', 7.1370, -73.1260);
