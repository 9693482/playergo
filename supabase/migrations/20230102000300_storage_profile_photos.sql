-- Storage bucket para fotos de perfil
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-photos',
  'profile-photos',
  true,
  5242880,
  '{image/png,image/jpeg,image/webp}'
)
on conflict (id) do nothing;

-- RLS: usuarios autenticados suben a su propia carpeta
CREATE POLICY "Users can upload own profile photo"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- RLS: cualquiera puede ver fotos de perfil (son públicas)
CREATE POLICY "Anyone can view profile photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-photos');

-- RLS: usuarios pueden actualizar sus propias fotos
CREATE POLICY "Users can update own profile photo"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- RLS: usuarios pueden borrar sus propias fotos
CREATE POLICY "Users can delete own profile photo"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Admin puede ver todas las fotos
CREATE POLICY "Admins can view all profile photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'profile-photos'
    AND public.is_admin()
  );
