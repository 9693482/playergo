-- ============================================================================
-- 011_storage_kyc.sql
-- Bucket y políticas de Storage para documentos de identidad (KYC).
-- ============================================================================

-- Crear bucket (público para poder previsualizar, acceso restringido por RLS)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'identity-documents',
  'identity-documents',
  true,
  5242880, -- 5 MB
  '{image/png,image/jpeg,image/webp}'
)
on conflict (id) do nothing;

-- El dueño (auth.uid) solo puede gestionar archivos dentro de su propia
-- carpeta (la primera parte del path es el user id).
drop policy if exists "KYC: usuario sube sus documentos" on storage.objects;
create policy "KYC: usuario sube sus documentos"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'identity-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "KYC: usuario lee sus documentos" on storage.objects;
create policy "KYC: usuario lee sus documentos"
on storage.objects for select
to authenticated
using (
  bucket_id = 'identity-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "KYC: usuario actualiza sus documentos" on storage.objects;
create policy "KYC: usuario actualiza sus documentos"
on storage.objects for update
to authenticated
using (
  bucket_id = 'identity-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Los administradores pueden leer los documentos para moderación.
drop policy if exists "KYC: admin lee documentos para moderación" on storage.objects;
create policy "KYC: admin lee documentos para moderación"
on storage.objects for select
to authenticated
using (
  bucket_id = 'identity-documents'
  and exists (
    select 1 from profiles where id = auth.uid() and role = 'ADMIN'
  )
);
