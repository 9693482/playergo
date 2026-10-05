-- ============================================================================
-- migrate_orphan_players.sql
-- Crea registros Player/Team para Profiles huérfanos.
-- Player huérfano: profile con role=PLAYER pero sin registro en players.
-- Team huérfano: profile con role=TEAM pero sin registro en teams.
-- Usa valores por defecto: Fútbol/Mediocampista, precio mínimo.
-- ============================================================================

-- Players huérfanos: crear registro con deporte/posición por defecto
INSERT INTO players (user_id, sport_id, position_id, price_per_match, bio, experience_years)
SELECT
  p.id,
  'a0000001-0000-0000-0000-000000000001'::uuid,  -- Fútbol
  'b0000001-0000-0000-0000-000000000003'::uuid,  -- Mediocampista
  20000.00,  -- Precio mínimo de platform_settings
  'Perfil completado automáticamente',
  0
FROM profiles p
LEFT JOIN players pl ON pl.user_id = p.id
WHERE p.role = 'PLAYER' AND pl.id IS NULL;

-- Teams huérfanos: crear registro con nombre por defecto
INSERT INTO teams (user_id, team_name, description)
SELECT
  p.id,
  'Mi Equipo',
  'Equipo registrado automáticamente'
FROM profiles p
LEFT JOIN teams t ON t.user_id = p.id
WHERE p.role = 'TEAM' AND t.id IS NULL;
