-- BeautyLink Africa — schéma relationnel de référence

create table if not exists public.currencies (
  code text primary key,
  name text not null,
  symbol text not null,
  decimals smallint not null default 0,
  active boolean not null default true
);

create table if not exists public.countries (
  code text primary key check (char_length(code)=2),
  name text not null,
  default_currency text not null references public.currencies(code),
  default_language text not null default 'fr',
  phone_prefix text,
  active boolean not null default false,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete cascade,
  display_name text not null,
  handle text unique,
  avatar_url text,
  cover_url text,
  bio text,
  city text,
  country_code text references public.countries(code) default 'SN',
  primary_role public.app_role not null default 'consumer',
  verification_status public.verification_status not null default 'draft',
  is_public boolean not null default true,
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_roles (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role public.app_role not null,
  granted_by uuid references public.profiles(id),
  granted_at timestamptz not null default now(),
  primary key(profile_id, role)
);

create table if not exists public.profile_private (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  email text,
  phone text,
  birth_date date,
  preferred_language text not null default 'fr',
  address_landmark text,
  emergency_contact jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  label text not null default 'Domicile',
  country_code text not null references public.countries(code) default 'SN',
  region text,
  city text not null,
  district text not null,
  landmark text,
  latitude numeric(9,6),
  longitude numeric(9,6),
  phone text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.consents (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  consent_type text not null,
  granted boolean not null,
  policy_version text not null,
  channel text,
  granted_at timestamptz,
  withdrawn_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.notification_preferences (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  in_app boolean not null default true,
  email boolean not null default false,
  sms boolean not null default false,
  whatsapp boolean not null default false,
  push boolean not null default false,
  quiet_hours_start time,
  quiet_hours_end time,
  categories jsonb not null default '{"transactional":true,"routine":true,"feedback":true,"appointments":true,"marketing":false}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.beauty_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  skin_type text,
  scalp_type text,
  hair_type text,
  concerns text[] not null default '{}',
  sensitivities text[] not null default '{}',
  fragrance_families text[] not null default '{}',
  fragrance_intensity text,
  monthly_budget_min numeric(12,2),
  monthly_budget_max numeric(12,2),
  habits jsonb not null default '{}'::jsonb,
  self_declared boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  domain text not null default 'beauty',
  label text not null,
  target_date date,
  status text not null default 'active',
  created_at timestamptz not null default now()
);

create table if not exists public.allergy_declarations (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  substance text not null,
  reaction_description text,
  severity text,
  confirmed_by_professional boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.media_assets (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id) on delete cascade,
  domain public.data_domain not null,
  visibility public.media_visibility not null default 'private',
  storage_bucket text not null,
  storage_path text not null,
  mime_type text not null,
  file_size_bytes bigint,
  caption text,
  captured_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(storage_bucket, storage_path)
);

create table if not exists public.access_grants (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id) on delete cascade,
  grantee_profile_id uuid not null references public.profiles(id) on delete cascade,
  resource_type text not null,
  resource_id uuid,
  permissions text[] not null default array['read'],
  purpose text,
  granted_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  check(owner_profile_id <> grantee_profile_id)
);

create table if not exists public.progress_entries (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  entry_date date not null default current_date,
  regularity_score numeric(5,2) check(regularity_score between 0 and 100),
  satisfaction_score numeric(3,2) check(satisfaction_score between 0 and 5),
  comfort_score numeric(3,2) check(comfort_score between 0 and 5),
  notes text,
  media_ids uuid[] not null default '{}',
  self_reported boolean not null default true,
  created_at timestamptz not null default now(),
  unique(profile_id, entry_date)
);

create table if not exists public.brands (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid references public.profiles(id) on delete set null,
  name text not null unique,
  slug text not null unique,
  logo_url text,
  description text,
  country_code text references public.countries(code),
  verification_status public.verification_status not null default 'pending',
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  brand_id uuid references public.brands(id) on delete set null,
  seller_profile_id uuid references public.profiles(id) on delete set null,
  sku text unique,
  name text not null,
  slug text not null unique,
  category text not null,
  audience text not null default 'unisex',
  description text,
  ingredients text[] not null default '{}',
  usage_instructions text,
  precautions text,
  origin_country text,
  base_price numeric(12,2) not null,
  currency_code text not null references public.currencies(code) default 'XOF',
  stock_quantity integer not null default 0,
  status text not null default 'draft',
  average_rating numeric(3,2) not null default 0,
  review_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  sku text unique,
  label text not null,
  attributes jsonb not null default '{}'::jsonb,
  price numeric(12,2) not null,
  stock_quantity integer not null default 0,
  active boolean not null default true
);

create table if not exists public.inventory_batches (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  variant_id uuid references public.product_variants(id) on delete cascade,
  batch_number text not null,
  supplier_name text,
  quantity_received integer not null,
  quantity_available integer not null,
  manufactured_at date,
  expires_at date,
  document_media_ids uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  unique(product_id, batch_number)
);

create table if not exists public.routines (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  status text not null default 'active',
  created_by_profile_id uuid references public.profiles(id) on delete set null,
  is_clinical boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.routine_items (
  id uuid primary key default gen_random_uuid(),
  routine_id uuid not null references public.routines(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  label text not null,
  moment text not null,
  sort_order integer not null,
  instructions text,
  frequency jsonb not null default '{}'::jsonb,
  started_at date,
  stopped_at date,
  status text not null default 'planned'
);

create table if not exists public.feedbacks (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  routine_item_id uuid references public.routine_items(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  rating numeric(3,2) check(rating between 0 and 5),
  reaction text,
  notes text,
  requires_follow_up boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.specialties (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  medical boolean not null default false,
  active boolean not null default true
);

create table if not exists public.professionals (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  professional_type public.app_role not null check(professional_type in ('beauty_professional','doctor')),
  title text not null,
  establishment_name text,
  license_number text,
  years_experience integer,
  languages text[] not null default '{}',
  specialties_summary text,
  verification_status public.verification_status not null default 'pending',
  verified_at timestamptz,
  verified_by uuid references public.profiles(id),
  consultation_enabled boolean not null default false,
  teleconsultation_enabled boolean not null default false,
  average_rating numeric(3,2) not null default 0,
  review_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.professional_credentials (
  id uuid primary key default gen_random_uuid(),
  professional_profile_id uuid not null references public.professionals(profile_id) on delete cascade,
  credential_type text not null,
  issuer text,
  credential_number text,
  issued_at date,
  expires_at date,
  document_media_id uuid references public.media_assets(id),
  verification_status public.verification_status not null default 'pending',
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  notes text
);

create table if not exists public.professional_specialties (
  professional_profile_id uuid not null references public.professionals(profile_id) on delete cascade,
  specialty_id uuid not null references public.specialties(id) on delete cascade,
  primary key(professional_profile_id, specialty_id)
);

create table if not exists public.professional_services (
  id uuid primary key default gen_random_uuid(),
  professional_profile_id uuid not null references public.professionals(profile_id) on delete cascade,
  name text not null,
  description text,
  duration_minutes integer not null,
  price numeric(12,2) not null,
  currency_code text not null references public.currencies(code),
  delivery_mode text not null,
  active boolean not null default true,
  is_medical boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.availability (
  id uuid primary key default gen_random_uuid(),
  professional_profile_id uuid not null references public.professionals(profile_id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'available',
  recurrence_rule text,
  check(ends_at > starts_at)
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  client_profile_id uuid not null references public.profiles(id) on delete cascade,
  professional_profile_id uuid not null references public.professionals(profile_id) on delete cascade,
  service_id uuid references public.professional_services(id),
  status public.appointment_status not null default 'requested',
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  mode text not null default 'video',
  reason text not null,
  questionnaire jsonb not null default '{}'::jsonb,
  amount numeric(12,2) not null default 0,
  currency_code text not null references public.currencies(code),
  consent_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check(ends_at > starts_at)
);

create table if not exists public.consultations (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid unique not null references public.appointments(id) on delete cascade,
  patient_profile_id uuid not null references public.profiles(id) on delete cascade,
  professional_profile_id uuid not null references public.professionals(profile_id) on delete cascade,
  status public.consultation_status not null default 'scheduled',
  preconsultation_answers jsonb not null default '{}'::jsonb,
  patient_shared_media_ids uuid[] not null default '{}',
  started_at timestamptz,
  ended_at timestamptz,
  patient_visible_summary text,
  follow_up_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.clinical_notes (
  id uuid primary key default gen_random_uuid(),
  consultation_id uuid not null references public.consultations(id) on delete cascade,
  author_profile_id uuid not null references public.profiles(id),
  note_text text not null,
  note_type text not null default 'private_note',
  patient_visible boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.care_plans (
  id uuid primary key default gen_random_uuid(),
  consultation_id uuid references public.consultations(id) on delete set null,
  client_profile_id uuid not null references public.profiles(id) on delete cascade,
  author_profile_id uuid not null references public.profiles(id),
  title text not null,
  summary text,
  instructions jsonb not null default '[]'::jsonb,
  starts_at date,
  ends_at date,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.video_sessions (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid unique not null references public.appointments(id) on delete cascade,
  provider text not null default 'sandbox',
  room_reference text,
  status text not null default 'created',
  started_at timestamptz,
  ended_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_profile_id uuid not null references public.profiles(id) on delete cascade,
  kind public.content_kind not null default 'social',
  visibility public.media_visibility not null default 'public',
  body text not null,
  tags text[] not null default '{}',
  sponsored_by_brand_id uuid references public.brands(id) on delete set null,
  published_at timestamptz,
  moderation_status text not null default 'approved',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_media (
  post_id uuid not null references public.posts(id) on delete cascade,
  media_id uuid not null references public.media_assets(id) on delete cascade,
  sort_order integer not null default 0,
  primary key(post_id, media_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_profile_id uuid not null references public.profiles(id) on delete cascade,
  parent_id uuid references public.comments(id) on delete cascade,
  body text not null,
  moderation_status text not null default 'approved',
  created_at timestamptz not null default now()
);

create table if not exists public.reactions (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  reaction_type text not null default 'like',
  created_at timestamptz not null default now(),
  primary key(profile_id, post_id)
);

create table if not exists public.saved_posts (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(profile_id, post_id)
);

create table if not exists public.follows (
  follower_profile_id uuid not null references public.profiles(id) on delete cascade,
  followed_profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(follower_profile_id, followed_profile_id),
  check(follower_profile_id <> followed_profile_id)
);

create table if not exists public.community_groups (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id),
  name text not null,
  slug text not null unique,
  description text,
  visibility text not null default 'public',
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.community_groups(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  member_role text not null default 'member',
  joined_at timestamptz not null default now(),
  primary key(group_id, profile_id)
);

create table if not exists public.care_carts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  name text not null default 'Ma routine',
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.care_cart_items (
  id uuid primary key default gen_random_uuid(),
  care_cart_id uuid not null references public.care_carts(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  variant_id uuid references public.product_variants(id),
  quantity integer not null default 1 check(quantity > 0),
  status public.care_cart_status not null default 'saved',
  selected_for_checkout boolean not null default false,
  recommended_by_profile_id uuid references public.profiles(id),
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(care_cart_id, product_id, variant_id)
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  profile_id uuid not null references public.profiles(id),
  seller_profile_id uuid references public.profiles(id),
  status public.order_status not null default 'draft',
  currency_code text not null references public.currencies(code),
  subtotal numeric(12,2) not null default 0,
  discount_total numeric(12,2) not null default 0,
  loyalty_total numeric(12,2) not null default 0,
  shipping_total numeric(12,2) not null default 0,
  consultation_total numeric(12,2) not null default 0,
  grand_total numeric(12,2) not null default 0,
  shipping_address jsonb not null default '{}'::jsonb,
  source_care_cart_id uuid references public.care_carts(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id),
  variant_id uuid references public.product_variants(id),
  product_snapshot jsonb not null,
  quantity integer not null check(quantity > 0),
  unit_price numeric(12,2) not null,
  line_total numeric(12,2) not null
);

create table if not exists public.payment_providers (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries(code),
  code text not null,
  display_name text not null,
  provider_type text not null,
  enabled boolean not null default false,
  sandbox_enabled boolean not null default true,
  public_config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(country_code, code)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id),
  order_id uuid references public.orders(id),
  appointment_id uuid references public.appointments(id),
  provider_id uuid references public.payment_providers(id),
  provider_reference text,
  idempotency_key text not null unique,
  status public.payment_status not null default 'created',
  amount numeric(12,2) not null,
  currency_code text not null references public.currencies(code),
  payment_type text not null default 'products',
  raw_status jsonb not null default '{}'::jsonb,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check((order_id is not null)::integer + (appointment_id is not null)::integer = 1)
);

create table if not exists public.shipping_zones (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries(code),
  name text not null,
  cities text[] not null default '{}',
  base_fee numeric(12,2) not null default 0,
  eta_min_hours integer not null default 24,
  eta_max_hours integer not null default 72,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.shipments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid unique not null references public.orders(id) on delete cascade,
  shipping_zone_id uuid references public.shipping_zones(id),
  carrier text,
  tracking_reference text,
  status text not null default 'pending',
  timeline jsonb not null default '[]'::jsonb,
  proof_media_id uuid references public.media_assets(id),
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  author_profile_id uuid not null references public.profiles(id),
  product_id uuid references public.products(id),
  professional_profile_id uuid references public.professionals(profile_id),
  order_id uuid references public.orders(id),
  rating integer not null check(rating between 1 and 5),
  title text,
  body text,
  verified_purchase boolean not null default false,
  moderation_status text not null default 'approved',
  created_at timestamptz not null default now()
);

create table if not exists public.favorites (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(profile_id, product_id)
);

create table if not exists public.returns (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id),
  profile_id uuid not null references public.profiles(id),
  reason text not null,
  status text not null default 'pending',
  resolution text,
  refund_payment_id uuid references public.payments(id),
  created_at timestamptz not null default now()
);

create table if not exists public.loyalty_transactions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id),
  order_id uuid references public.orders(id),
  points integer not null,
  reason text not null,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_profile_id uuid not null references public.profiles(id),
  referred_profile_id uuid unique references public.profiles(id),
  code text not null unique,
  status text not null default 'invited',
  reward_points integer not null default 0,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  conversation_type text not null default 'direct',
  domain public.data_domain not null default 'community',
  title text,
  appointment_id uuid references public.appointments(id),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  member_role text not null default 'member',
  last_read_at timestamptz,
  muted boolean not null default false,
  blocked boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key(conversation_id, profile_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_profile_id uuid not null references public.profiles(id),
  body text,
  message_type text not null default 'text',
  ai_generated boolean not null default false,
  moderation_status text not null default 'approved',
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz
);

create table if not exists public.message_attachments (
  message_id uuid not null references public.messages(id) on delete cascade,
  media_id uuid not null references public.media_assets(id) on delete cascade,
  primary key(message_id, media_id)
);

create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  reminder_type text not null,
  channel text not null default 'in_app',
  schedule jsonb not null default '{}'::jsonb,
  next_run_at timestamptz,
  active boolean not null default true,
  related_entity_type text,
  related_entity_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.campaigns (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid references public.profiles(id),
  brand_id uuid references public.brands(id),
  name text not null,
  audience_definition jsonb not null default '{}'::jsonb,
  channels text[] not null default '{}',
  template jsonb not null default '{}'::jsonb,
  status text not null default 'draft',
  scheduled_at timestamptz,
  sent_count integer not null default 0,
  conversion_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_interactions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id),
  professional_profile_id uuid references public.professionals(profile_id),
  use_case text not null,
  model_provider text,
  model_name text,
  model_version text,
  input_summary text,
  output_summary text,
  safety_classification jsonb not null default '{}'::jsonb,
  escalated_to_human boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_profile_id uuid references public.profiles(id),
  target_type text not null,
  target_id uuid not null,
  reason text not null,
  details text,
  status text not null default 'open',
  priority text not null default 'normal',
  assigned_to uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.moderation_actions (
  id uuid primary key default gen_random_uuid(),
  report_id uuid references public.reports(id),
  moderator_profile_id uuid not null references public.profiles(id),
  action_type text not null,
  reason text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_profile_id uuid references public.profiles(id),
  action text not null,
  domain public.data_domain not null,
  target_type text not null,
  target_id uuid,
  ip_hash text,
  user_agent text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.data_requests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  request_type text not null,
  status text not null default 'requested',
  details text,
  submitted_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists idx_profiles_auth_user on public.profiles(auth_user_id);
create index if not exists idx_products_status_category on public.products(status, category);
create index if not exists idx_posts_published on public.posts(published_at desc);
create index if not exists idx_appointments_parties on public.appointments(client_profile_id, professional_profile_id, starts_at);
create index if not exists idx_messages_conversation on public.messages(conversation_id, created_at);
create index if not exists idx_orders_profile_status on public.orders(profile_id, status);
create index if not exists idx_media_owner_domain on public.media_assets(owner_profile_id, domain);
