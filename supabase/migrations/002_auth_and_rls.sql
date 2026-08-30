-- BeautyLink Africa — identité Supabase, fonctions d'autorisation et RLS

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id from public.profiles p where p.auth_user_id = auth.uid() limit 1
$$;

create or replace function public.has_role(required_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_roles ur
    where ur.profile_id = public.current_profile_id() and ur.role = required_role
  )
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_role('admin') or public.has_role('super_admin')
$$;

create or replace function public.is_conversation_member(conversation_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = conversation_uuid
      and cm.profile_id = public.current_profile_id()
      and cm.blocked = false
  )
$$;

create or replace function public.has_active_access(resource_kind text, resource_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.access_grants ag
    where ag.grantee_profile_id = public.current_profile_id()
      and ag.resource_type = resource_kind
      and ag.resource_id = resource_uuid
      and ag.revoked_at is null
      and (ag.expires_at is null or ag.expires_at > now())
      and 'read' = any(ag.permissions)
  )
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  profile_uuid uuid;
  proposed_name text;
begin
  proposed_name := coalesce(
    nullif(new.raw_user_meta_data->>'full_name',''),
    nullif(new.raw_user_meta_data->>'name',''),
    nullif(split_part(coalesce(new.email,new.phone,'Membre BeautyLink'),'@',1),''),
    'Membre BeautyLink'
  );

  insert into public.profiles(auth_user_id, display_name, avatar_url, country_code, primary_role, verification_status)
  values(
    new.id,
    proposed_name,
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture'),
    coalesce(nullif(new.raw_user_meta_data->>'country_code',''),'SN'),
    'consumer',
    'draft'
  )
  on conflict(auth_user_id) do update set
    display_name = excluded.display_name,
    avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
    updated_at = now()
  returning id into profile_uuid;

  insert into public.user_roles(profile_id, role) values(profile_uuid, 'consumer') on conflict do nothing;
  insert into public.profile_private(profile_id, email, phone, preferred_language)
  values(profile_uuid, new.email, new.phone, coalesce(nullif(new.raw_user_meta_data->>'preferred_language',''),'fr'))
  on conflict(profile_id) do update set
    email = coalesce(excluded.email, public.profile_private.email),
    phone = coalesce(excluded.phone, public.profile_private.phone),
    updated_at = now();
  insert into public.notification_preferences(profile_id) values(profile_uuid) on conflict do nothing;
  insert into public.beauty_profiles(profile_id) values(profile_uuid) on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_beautylink on auth.users;
create trigger on_auth_user_created_beautylink
after insert or update of email, phone, raw_user_meta_data on auth.users
for each row execute function public.handle_new_auth_user();

DO $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles','profile_private','notification_preferences','beauty_profiles','routines','posts',
    'care_carts','care_cart_items','orders','payments','conversations','clinical_notes','reminders'
  ] loop
    if exists(select 1 from information_schema.columns where table_schema='public' and information_schema.columns.table_name=table_name and column_name='updated_at') then
      execute format('drop trigger if exists %I on public.%I', 'touch_'||table_name, table_name);
      execute format('create trigger %I before update on public.%I for each row execute function public.touch_updated_at()', 'touch_'||table_name, table_name);
    end if;
  end loop;
end $$;

DO $$
declare
  table_name text;
begin
  for table_name in select tablename from pg_tables where schemaname='public' loop
    execute format('alter table public.%I enable row level security', table_name);
  end loop;
end $$;

-- Référentiels publics
drop policy if exists currencies_read on public.currencies;
create policy currencies_read on public.currencies for select using(active or public.is_admin());
drop policy if exists currencies_admin on public.currencies;
create policy currencies_admin on public.currencies for all using(public.is_admin()) with check(public.is_admin());

drop policy if exists countries_read on public.countries;
create policy countries_read on public.countries for select using(active or public.is_admin());
drop policy if exists countries_admin on public.countries;
create policy countries_admin on public.countries for all using(public.is_admin()) with check(public.is_admin());

drop policy if exists specialties_read on public.specialties;
create policy specialties_read on public.specialties for select using(active or public.is_admin());
drop policy if exists specialties_admin on public.specialties;
create policy specialties_admin on public.specialties for all using(public.is_admin()) with check(public.is_admin());

drop policy if exists payment_providers_read on public.payment_providers;
create policy payment_providers_read on public.payment_providers for select using(enabled or public.is_admin());
drop policy if exists payment_providers_admin on public.payment_providers;
create policy payment_providers_admin on public.payment_providers for all using(public.is_admin()) with check(public.is_admin());

drop policy if exists shipping_zones_read on public.shipping_zones;
create policy shipping_zones_read on public.shipping_zones for select using(active or public.is_admin());
drop policy if exists shipping_zones_admin on public.shipping_zones;
create policy shipping_zones_admin on public.shipping_zones for all using(public.is_admin()) with check(public.is_admin());

-- Profils et données privées
drop policy if exists profiles_public_read on public.profiles;
create policy profiles_public_read on public.profiles for select using(is_public or id=public.current_profile_id() or public.is_admin());
drop policy if exists profiles_owner_write on public.profiles;
create policy profiles_owner_write on public.profiles for all using(id=public.current_profile_id() or public.is_admin()) with check(id=public.current_profile_id() or public.is_admin());

drop policy if exists profile_private_owner on public.profile_private;
create policy profile_private_owner on public.profile_private for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists user_roles_self_admin on public.user_roles;
create policy user_roles_self_admin on public.user_roles for select using(profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists user_roles_admin_write on public.user_roles;
create policy user_roles_admin_write on public.user_roles for all using(public.is_admin()) with check(public.is_admin());

drop policy if exists addresses_owner on public.addresses;
create policy addresses_owner on public.addresses for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists consents_owner on public.consents;
create policy consents_owner on public.consents for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists notifications_owner on public.notification_preferences;
create policy notifications_owner on public.notification_preferences for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists beauty_profiles_owner_shared on public.beauty_profiles;
create policy beauty_profiles_owner_shared on public.beauty_profiles for select using(profile_id=public.current_profile_id() or public.has_active_access('beauty_profile', profile_id) or public.is_admin());
drop policy if exists beauty_profiles_owner_write on public.beauty_profiles;
create policy beauty_profiles_owner_write on public.beauty_profiles for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists goals_owner on public.goals;
create policy goals_owner on public.goals for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists allergies_owner on public.allergy_declarations;
create policy allergies_owner on public.allergy_declarations for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists progress_owner_shared on public.progress_entries;
create policy progress_owner_shared on public.progress_entries for select using(profile_id=public.current_profile_id() or public.has_active_access('progress_entry', id) or public.is_admin());
drop policy if exists progress_owner_write on public.progress_entries;
create policy progress_owner_write on public.progress_entries for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists media_owner_public_shared on public.media_assets;
create policy media_owner_public_shared on public.media_assets for select using(visibility='public' or owner_profile_id=public.current_profile_id() or public.has_active_access('media', id) or public.is_admin());
drop policy if exists media_owner_write on public.media_assets;
create policy media_owner_write on public.media_assets for all using(owner_profile_id=public.current_profile_id() or public.is_admin()) with check(owner_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists access_grants_parties on public.access_grants;
create policy access_grants_parties on public.access_grants for select using(owner_profile_id=public.current_profile_id() or grantee_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists access_grants_owner_write on public.access_grants;
create policy access_grants_owner_write on public.access_grants for all using(owner_profile_id=public.current_profile_id() or public.is_admin()) with check(owner_profile_id=public.current_profile_id() or public.is_admin());

-- Catalogue
drop policy if exists brands_public on public.brands;
create policy brands_public on public.brands for select using(verification_status='verified' or owner_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists brands_owner on public.brands;
create policy brands_owner on public.brands for all using(owner_profile_id=public.current_profile_id() or public.is_admin()) with check(owner_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists products_public on public.products;
create policy products_public on public.products for select using(status='active' or seller_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists products_seller on public.products;
create policy products_seller on public.products for all using(seller_profile_id=public.current_profile_id() or public.is_admin()) with check(seller_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists variants_public on public.product_variants;
create policy variants_public on public.product_variants for select using(active or public.is_admin());
drop policy if exists variants_seller on public.product_variants;
create policy variants_seller on public.product_variants for all using(public.is_admin() or exists(select 1 from public.products p where p.id=product_id and p.seller_profile_id=public.current_profile_id())) with check(public.is_admin() or exists(select 1 from public.products p where p.id=product_id and p.seller_profile_id=public.current_profile_id()));

drop policy if exists batches_seller on public.inventory_batches;
create policy batches_seller on public.inventory_batches for all using(public.is_admin() or exists(select 1 from public.products p where p.id=product_id and p.seller_profile_id=public.current_profile_id())) with check(public.is_admin() or exists(select 1 from public.products p where p.id=product_id and p.seller_profile_id=public.current_profile_id()));

-- Routines
drop policy if exists routines_participants on public.routines;
create policy routines_participants on public.routines for all using(profile_id=public.current_profile_id() or created_by_profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or created_by_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists routine_items_via_routine on public.routine_items;
create policy routine_items_via_routine on public.routine_items for all using(public.is_admin() or exists(select 1 from public.routines r where r.id=routine_id and (r.profile_id=public.current_profile_id() or r.created_by_profile_id=public.current_profile_id()))) with check(public.is_admin() or exists(select 1 from public.routines r where r.id=routine_id and (r.profile_id=public.current_profile_id() or r.created_by_profile_id=public.current_profile_id())));

drop policy if exists feedback_owner on public.feedbacks;
create policy feedback_owner on public.feedbacks for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

-- Professionnels et clinique
drop policy if exists professionals_public_owner on public.professionals;
create policy professionals_public_owner on public.professionals for select using(verification_status='verified' or profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists professionals_owner_write on public.professionals;
create policy professionals_owner_write on public.professionals for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists credentials_owner_admin on public.professional_credentials;
create policy credentials_owner_admin on public.professional_credentials for all using(professional_profile_id=public.current_profile_id() or public.is_admin()) with check(professional_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists professional_specialties_visible on public.professional_specialties;
create policy professional_specialties_visible on public.professional_specialties for select using(true);
drop policy if exists professional_specialties_owner on public.professional_specialties;
create policy professional_specialties_owner on public.professional_specialties for all using(professional_profile_id=public.current_profile_id() or public.is_admin()) with check(professional_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists services_public on public.professional_services;
create policy services_public on public.professional_services for select using(active or professional_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists services_owner on public.professional_services;
create policy services_owner on public.professional_services for all using(professional_profile_id=public.current_profile_id() or public.is_admin()) with check(professional_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists availability_public on public.availability;
create policy availability_public on public.availability for select using(status='available' or professional_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists availability_owner on public.availability;
create policy availability_owner on public.availability for all using(professional_profile_id=public.current_profile_id() or public.is_admin()) with check(professional_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists appointments_participants on public.appointments;
create policy appointments_participants on public.appointments for select using(client_profile_id=public.current_profile_id() or professional_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists appointments_client_create on public.appointments;
create policy appointments_client_create on public.appointments for insert with check(client_profile_id=public.current_profile_id());
drop policy if exists appointments_participant_update on public.appointments;
create policy appointments_participant_update on public.appointments for update using(client_profile_id=public.current_profile_id() or professional_profile_id=public.current_profile_id() or public.is_admin()) with check(client_profile_id=public.current_profile_id() or professional_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists consultations_participants on public.consultations;
create policy consultations_participants on public.consultations for select using(patient_profile_id=public.current_profile_id() or professional_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists consultations_prof_write on public.consultations;
create policy consultations_prof_write on public.consultations for all using(professional_profile_id=public.current_profile_id() or public.is_admin()) with check(professional_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists clinical_notes_author_patient on public.clinical_notes;
create policy clinical_notes_author_patient on public.clinical_notes for select using(author_profile_id=public.current_profile_id() or public.is_admin() or (patient_visible and exists(select 1 from public.consultations c where c.id=consultation_id and c.patient_profile_id=public.current_profile_id())));
drop policy if exists clinical_notes_author_write on public.clinical_notes;
create policy clinical_notes_author_write on public.clinical_notes for all using(author_profile_id=public.current_profile_id() or public.is_admin()) with check(author_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists care_plans_participants on public.care_plans;
create policy care_plans_participants on public.care_plans for select using(client_profile_id=public.current_profile_id() or author_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists care_plans_author on public.care_plans;
create policy care_plans_author on public.care_plans for all using(author_profile_id=public.current_profile_id() or public.is_admin()) with check(author_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists video_participants on public.video_sessions;
create policy video_participants on public.video_sessions for select using(public.is_admin() or exists(select 1 from public.appointments a where a.id=appointment_id and (a.client_profile_id=public.current_profile_id() or a.professional_profile_id=public.current_profile_id())));

-- Réseau social
drop policy if exists posts_public on public.posts;
create policy posts_public on public.posts for select using((visibility='public' and moderation_status='approved') or author_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists posts_author on public.posts;
create policy posts_author on public.posts for all using(author_profile_id=public.current_profile_id() or public.is_admin()) with check(author_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists post_media_visible on public.post_media;
create policy post_media_visible on public.post_media for select using(exists(select 1 from public.posts p where p.id=post_id and ((p.visibility='public' and p.moderation_status='approved') or p.author_profile_id=public.current_profile_id() or public.is_admin())));
drop policy if exists post_media_author on public.post_media;
create policy post_media_author on public.post_media for all using(public.is_admin() or exists(select 1 from public.posts p where p.id=post_id and p.author_profile_id=public.current_profile_id())) with check(public.is_admin() or exists(select 1 from public.posts p where p.id=post_id and p.author_profile_id=public.current_profile_id()));

drop policy if exists comments_public on public.comments;
create policy comments_public on public.comments for select using(moderation_status='approved' or author_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists comments_author on public.comments;
create policy comments_author on public.comments for all using(author_profile_id=public.current_profile_id() or public.is_admin()) with check(author_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists reactions_owner on public.reactions;
create policy reactions_owner on public.reactions for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists saved_posts_owner on public.saved_posts;
create policy saved_posts_owner on public.saved_posts for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists follows_owner on public.follows;
create policy follows_owner on public.follows for all using(follower_profile_id=public.current_profile_id() or public.is_admin()) with check(follower_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists groups_public on public.community_groups;
create policy groups_public on public.community_groups for select using(visibility='public' or owner_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists groups_owner on public.community_groups;
create policy groups_owner on public.community_groups for all using(owner_profile_id=public.current_profile_id() or public.is_admin()) with check(owner_profile_id=public.current_profile_id() or public.is_admin());

drop policy if exists group_members_visible on public.group_members;
create policy group_members_visible on public.group_members for select using(profile_id=public.current_profile_id() or public.is_admin() or exists(select 1 from public.community_groups g where g.id=group_id and g.visibility='public'));
drop policy if exists group_members_manage on public.group_members;
create policy group_members_manage on public.group_members for all using(profile_id=public.current_profile_id() or public.is_admin() or exists(select 1 from public.community_groups g where g.id=group_id and g.owner_profile_id=public.current_profile_id())) with check(profile_id=public.current_profile_id() or public.is_admin() or exists(select 1 from public.community_groups g where g.id=group_id and g.owner_profile_id=public.current_profile_id()));

-- Commerce
drop policy if exists carts_owner on public.care_carts;
create policy carts_owner on public.care_carts for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists cart_items_owner on public.care_cart_items;
create policy cart_items_owner on public.care_cart_items for all using(public.is_admin() or exists(select 1 from public.care_carts c where c.id=care_cart_id and c.profile_id=public.current_profile_id())) with check(public.is_admin() or exists(select 1 from public.care_carts c where c.id=care_cart_id and c.profile_id=public.current_profile_id()));

drop policy if exists orders_parties on public.orders;
create policy orders_parties on public.orders for all using(profile_id=public.current_profile_id() or seller_profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or seller_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists order_items_parties on public.order_items;
create policy order_items_parties on public.order_items for select using(public.is_admin() or exists(select 1 from public.orders o where o.id=order_id and (o.profile_id=public.current_profile_id() or o.seller_profile_id=public.current_profile_id())));

drop policy if exists payments_owner_admin on public.payments;
create policy payments_owner_admin on public.payments for select using(profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists shipments_parties on public.shipments;
create policy shipments_parties on public.shipments for select using(public.is_admin() or exists(select 1 from public.orders o where o.id=order_id and (o.profile_id=public.current_profile_id() or o.seller_profile_id=public.current_profile_id())));

drop policy if exists reviews_public on public.reviews;
create policy reviews_public on public.reviews for select using(moderation_status='approved' or author_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists reviews_author on public.reviews;
create policy reviews_author on public.reviews for all using(author_profile_id=public.current_profile_id() or public.is_admin()) with check(author_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists favorites_owner on public.favorites;
create policy favorites_owner on public.favorites for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists returns_parties on public.returns;
create policy returns_parties on public.returns for all using(profile_id=public.current_profile_id() or public.is_admin() or exists(select 1 from public.orders o where o.id=order_id and o.seller_profile_id=public.current_profile_id())) with check(profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists loyalty_owner on public.loyalty_transactions;
create policy loyalty_owner on public.loyalty_transactions for select using(profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists referrals_parties on public.referrals;
create policy referrals_parties on public.referrals for select using(referrer_profile_id=public.current_profile_id() or referred_profile_id=public.current_profile_id() or public.is_admin());

-- Messagerie
drop policy if exists conversations_member on public.conversations;
create policy conversations_member on public.conversations for select using(public.is_conversation_member(id) or created_by=public.current_profile_id() or public.is_admin());
drop policy if exists conversations_create on public.conversations;
create policy conversations_create on public.conversations for insert with check(created_by=public.current_profile_id() or public.is_admin());
drop policy if exists conversation_members_member on public.conversation_members;
create policy conversation_members_member on public.conversation_members for select using(public.is_conversation_member(conversation_id) or profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists conversation_members_add on public.conversation_members;
create policy conversation_members_add on public.conversation_members for insert with check(profile_id=public.current_profile_id() or public.is_admin() or exists(select 1 from public.conversations c where c.id=conversation_id and c.created_by=public.current_profile_id()));
drop policy if exists messages_member_read on public.messages;
create policy messages_member_read on public.messages for select using(public.is_conversation_member(conversation_id) or public.is_admin());
drop policy if exists messages_member_insert on public.messages;
create policy messages_member_insert on public.messages for insert with check(sender_profile_id=public.current_profile_id() and public.is_conversation_member(conversation_id));
drop policy if exists message_attachments_member_read on public.message_attachments;
create policy message_attachments_member_read on public.message_attachments for select using(public.is_admin() or exists(select 1 from public.messages m where m.id=message_id and public.is_conversation_member(m.conversation_id)));

-- Outils utilisateur et gouvernance
drop policy if exists reminders_owner on public.reminders;
create policy reminders_owner on public.reminders for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists campaigns_owner on public.campaigns;
create policy campaigns_owner on public.campaigns for all using(owner_profile_id=public.current_profile_id() or public.is_admin() or exists(select 1 from public.brands b where b.id=brand_id and b.owner_profile_id=public.current_profile_id())) with check(owner_profile_id=public.current_profile_id() or public.is_admin() or exists(select 1 from public.brands b where b.id=brand_id and b.owner_profile_id=public.current_profile_id()));
drop policy if exists ai_owner on public.ai_interactions;
create policy ai_owner on public.ai_interactions for select using(profile_id=public.current_profile_id() or professional_profile_id=public.current_profile_id() or public.is_admin());
drop policy if exists reports_create on public.reports;
create policy reports_create on public.reports for insert with check(reporter_profile_id=public.current_profile_id() or reporter_profile_id is null);
drop policy if exists reports_moderate on public.reports;
create policy reports_moderate on public.reports for select using(reporter_profile_id=public.current_profile_id() or public.is_admin() or public.has_role('moderator'));
drop policy if exists moderation_actions_moderator on public.moderation_actions;
create policy moderation_actions_moderator on public.moderation_actions for all using(public.is_admin() or public.has_role('moderator')) with check(moderator_profile_id=public.current_profile_id() and (public.is_admin() or public.has_role('moderator')));
drop policy if exists audit_admin on public.audit_logs;
create policy audit_admin on public.audit_logs for select using(public.is_admin());
drop policy if exists data_requests_owner on public.data_requests;
create policy data_requests_owner on public.data_requests for all using(profile_id=public.current_profile_id() or public.is_admin()) with check(profile_id=public.current_profile_id() or public.is_admin());
