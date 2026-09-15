-- FASE 29: Verificación de identidad
-- Separar perfil deportivo de identidad legal

-- ============================================
-- 1. DOCUMENT TYPES ENUM
-- ============================================
CREATE TYPE document_type AS ENUM (
  'CEDULA_CIUDADANIA',
  'CEDULA_EXTRANJERIA',
  'PASAPORTE',
  'NIT',
  'RUT'
);

-- ============================================
-- 2. IDENTITY DOCUMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS identity_documents (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_type document_type NOT NULL,
  document_number TEXT NOT NULL,
  document_front_url TEXT,
  document_back_url TEXT,
  selfie_url TEXT,
  status verification_status DEFAULT 'PENDING',
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, document_type)
);

CREATE INDEX IF NOT EXISTS idx_identity_documents_user ON identity_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_identity_documents_status ON identity_documents(status);

ALTER TABLE identity_documents ENABLE ROW LEVEL SECURITY;

-- Users can read/update their own documents
CREATE POLICY "user_own_documents"
  ON identity_documents FOR ALL
  USING (auth.uid() = user_id);

-- Admins can read all documents
CREATE POLICY "admin_all_documents"
  ON identity_documents FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );

-- ============================================
-- 3. UPDATE VERIFICATION STATUS FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_user_verification_status()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET verification_status = NEW.status,
      updated_at = NOW()
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_identity_doc_status_change
  AFTER UPDATE OF status ON identity_documents
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION update_user_verification_status();

-- ============================================
-- 4. AUDIT LOG FOR VERIFICATION
-- ============================================
CREATE OR REPLACE FUNCTION log_verification_audit()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    INSERT INTO audit_log (action, entity, entity_id, details)
    VALUES (
      'verification:' || NEW.status::text,
      'identity_document',
      NEW.id,
      jsonb_build_object(
        'user_id', NEW.user_id,
        'document_type', NEW.document_type,
        'old_status', OLD.status,
        'new_status', NEW.status,
        'rejection_reason', NEW.rejection_reason
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_verification_audit
  AFTER UPDATE ON identity_documents
  FOR EACH ROW
  EXECUTE FUNCTION log_verification_audit();
