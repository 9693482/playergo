-- ============================================================================
-- make_kyc_bucket_private.sql
-- SEGURIDAD: El bucket identity-documents estaba en public: true,
-- permitiendo acceso directo a URLs de documentos de identidad.
-- Ahora es privado. Solo el dueño y admin pueden acceder via
-- políticas de Storage.
-- ============================================================================

-- Cambiar bucket a privado
UPDATE storage.buckets
SET public = false
WHERE id = 'identity-documents';

-- La política de admin ya existe del archivo 011_storage_kyc.sql.
-- La política de usuario ya existe del archivo 011_storage_kyc.sql.
-- No necesitamos crear nuevas políticas, solo cambiar public a false.

-- Agregar política para que admin pueda usar signed URLs
-- (las políticas existentes de SELECT ya permiten a admin leer,
-- pero con bucket privado necesitamos que admin pueda generar signed URLs)
DROP POLICY IF EXISTS "KYC: admin lee documentos para moderación" ON storage.objects;
CREATE POLICY "KYC: admin lee documentos para moderación"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'identity-documents'
  AND exists (
    select 1 from profiles where id = auth.uid() and role = 'ADMIN'
  )
);
