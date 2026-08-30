-- BeautyLink Africa — buckets et politiques Storage
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values
  ('public-content','public-content',true,52428800,array['image/jpeg','image/png','image/webp','video/mp4']),
  ('product-media','product-media',true,52428800,array['image/jpeg','image/png','image/webp','video/mp4']),
  ('professional-portfolios','professional-portfolios',true,104857600,array['image/jpeg','image/png','image/webp','video/mp4']),
  ('private-user-gallery','private-user-gallery',false,104857600,array['image/jpeg','image/png','image/webp','video/mp4']),
  ('clinical-attachments','clinical-attachments',false,104857600,array['image/jpeg','image/png','image/webp','video/mp4','application/pdf']),
  ('consultation-documents','consultation-documents',false,52428800,array['application/pdf','image/jpeg','image/png'])
on conflict(id) do update set
  public=excluded.public,
  file_size_limit=excluded.file_size_limit,
  allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists beautylink_public_media_read on storage.objects;
create policy beautylink_public_media_read
on storage.objects for select
using(bucket_id in ('public-content','product-media','professional-portfolios'));

drop policy if exists beautylink_owner_upload on storage.objects;
create policy beautylink_owner_upload
on storage.objects for insert to authenticated
with check(
  bucket_id in ('public-content','product-media','professional-portfolios','private-user-gallery','clinical-attachments','consultation-documents')
  and (storage.foldername(name))[1]=auth.uid()::text
);

drop policy if exists beautylink_owner_private_read on storage.objects;
create policy beautylink_owner_private_read
on storage.objects for select to authenticated
using(
  bucket_id in ('private-user-gallery','clinical-attachments','consultation-documents')
  and (storage.foldername(name))[1]=auth.uid()::text
);

drop policy if exists beautylink_owner_update on storage.objects;
create policy beautylink_owner_update
on storage.objects for update to authenticated
using((storage.foldername(name))[1]=auth.uid()::text)
with check((storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists beautylink_owner_delete on storage.objects;
create policy beautylink_owner_delete
on storage.objects for delete to authenticated
using((storage.foldername(name))[1]=auth.uid()::text);

-- Le partage clinique avec un professionnel doit passer par une Edge Function
-- qui vérifie access_grants puis génère une URL signée temporaire.
