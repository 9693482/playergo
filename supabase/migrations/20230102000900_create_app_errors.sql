-- ============================================================================
-- create_app_errors_table.sql
-- Tabla para tracking de errores de la aplicación.
-- Permite monitorear errores sin necesidad de Firebase Crashlytics.
-- Solo admins pueden leer los errores.
-- ============================================================================

CREATE TABLE IF NOT EXISTS app_errors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level TEXT NOT NULL CHECK (level IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')),
  message TEXT NOT NULL,
  error_text TEXT,
  stack_trace TEXT,
  screen TEXT,
  user_id UUID REFERENCES profiles(id),
  platform TEXT,
  app_version TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE app_errors ENABLE ROW LEVEL SECURITY;

-- Index para consultas rápidas
CREATE INDEX idx_app_errors_level ON app_errors(level);
CREATE INDEX idx_app_errors_created ON app_errors(created_at DESC);
CREATE INDEX idx_app_errors_screen ON app_errors(screen);

-- Solo admin puede leer errores
CREATE POLICY "Admin can read app errors"
  ON app_errors FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- Cualquier usuario autenticado puede insertar errores
CREATE POLICY "Authenticated users can insert errors"
  ON app_errors FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Auto-eliminar errores mayores a 30 días
CREATE OR REPLACE FUNCTION cleanup_old_errors()
RETURNS void AS $$
BEGIN
  DELETE FROM app_errors WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;
