-- BeautyLink Africa — extensions, enums et utilitaires de base
create extension if not exists pgcrypto;

DO $$ BEGIN CREATE TYPE public.app_role AS ENUM ('consumer','beauty_professional','doctor','brand_seller','moderator','admin','super_admin'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.data_domain AS ENUM ('community','commerce','clinical','identity','system'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.verification_status AS ENUM ('draft','pending','verified','rejected','suspended'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.media_visibility AS ENUM ('public','followers','private','shared','clinical'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.content_kind AS ENUM ('educational','testimonial','sponsored','medical','question','social'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.care_cart_status AS ENUM ('recommended','saved','to_buy','validated','paid','delivered','started','finished','rated','stopped'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.order_status AS ENUM ('draft','pending_payment','paid','confirmed','preparing','shipped','out_for_delivery','delivered','cancelled','returned','refunded','partially_refunded'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.payment_status AS ENUM ('created','pending','paid','failed','expired','cancelled','refunded','partially_refunded'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.appointment_status AS ENUM ('requested','pending_payment','confirmed','checked_in','in_progress','completed','cancelled','no_show'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.consultation_status AS ENUM ('scheduled','waiting_room','in_progress','completed','cancelled','follow_up'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;
