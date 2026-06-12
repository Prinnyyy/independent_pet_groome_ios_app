create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  apple_user_id text unique,
  display_name text,
  avatar_url text,
  city text,
  zip_code text,
  language_preference text default 'en',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

create table public.pets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  name text not null,
  species text not null check (species in ('dog', 'cat')),
  breed text,
  breed_notes text,
  weight numeric,
  age numeric,
  sex text,
  coat_type text,
  coat_condition text,
  temperament text[] default '{}',
  health_notes text,
  grooming_history text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  ai_detected_breed jsonb,
  ai_breed_confidence numeric,
  ai_detected_coat_type text,
  ai_detected_size text,
  ai_risk_flags text[] default '{}',
  ai_profile_summary text,
  ai_last_analyzed_at timestamp with time zone
);

create table public.pet_photos (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid references public.pets(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  image_url text not null,
  photo_type text,
  is_primary boolean default false,
  created_at timestamp with time zone default now()
);

create table public.groomers (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references public.users(id) on delete set null,
  name text not null,
  profile_photo_url text,
  bio text,
  city text,
  zip_code text,
  service_radius numeric,
  service_areas text[] default '{}',
  languages text[] default '{}',
  years_experience numeric,
  service_methods text[] default '{}',
  accepts_dogs boolean default true,
  accepts_cats boolean default false,
  size_accepted text[] default '{}',
  specialties text[] default '{}',
  price_min numeric,
  price_max numeric,
  small_dog_price_min numeric,
  small_dog_price_max numeric,
  medium_dog_price_min numeric,
  medium_dog_price_max numeric,
  large_dog_price_min numeric,
  large_dog_price_max numeric,
  cat_price_min numeric,
  cat_price_max numeric,
  phone text,
  sms_number text,
  instagram_url text,
  wechat_id text,
  website_url text,
  email text,
  is_verified boolean default false,
  status text default 'draft' check (status in ('draft', 'published', 'hidden')),
  rating numeric default 0,
  review_count integer default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  ai_summary text,
  ai_skill_tags text[] default '{}',
  ai_review_summary text,
  ai_last_processed_at timestamp with time zone
);

create table public.groomer_portfolio (
  id uuid primary key default gen_random_uuid(),
  groomer_id uuid references public.groomers(id) on delete cascade,
  image_url text not null,
  before_image_url text,
  after_image_url text,
  pet_species text check (pet_species in ('dog', 'cat')),
  breed text,
  service_type text,
  style_name text,
  coat_condition text,
  caption text,
  is_hidden boolean default false,
  created_at timestamp with time zone default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  groomer_id uuid references public.groomers(id) on delete cascade,
  pet_id uuid references public.pets(id) on delete set null,
  overall_rating numeric not null check (overall_rating >= 1 and overall_rating <= 5),
  grooming_result_rating numeric check (grooming_result_rating >= 1 and grooming_result_rating <= 5),
  communication_rating numeric check (communication_rating >= 1 and communication_rating <= 5),
  patience_rating numeric check (patience_rating >= 1 and patience_rating <= 5),
  punctuality_rating numeric check (punctuality_rating >= 1 and punctuality_rating <= 5),
  price_transparency_rating numeric check (price_transparency_rating >= 1 and price_transparency_rating <= 5),
  would_rebook boolean,
  service_type text,
  review_text text,
  service_date date,
  status text default 'published' check (status in ('published', 'hidden', 'flagged', 'deleted')),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  ai_sentiment text,
  ai_topics text[] default '{}',
  ai_risk_flag boolean default false,
  ai_summary text
);

create table public.review_photos (
  id uuid primary key default gen_random_uuid(),
  review_id uuid references public.reviews(id) on delete cascade,
  image_url text not null,
  photo_type text,
  created_at timestamp with time zone default now()
);

create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  target_type text not null check (target_type in ('groomer', 'portfolio', 'review')),
  target_id uuid not null,
  created_at timestamp with time zone default now(),
  unique (user_id, target_type, target_id)
);

create table public.contact_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  groomer_id uuid references public.groomers(id) on delete cascade,
  pet_id uuid references public.pets(id) on delete set null,
  contact_method text not null check (contact_method in ('phone', 'sms', 'instagram', 'wechat', 'website', 'email', 'quote_request')),
  created_at timestamp with time zone default now()
);

create table public.grooming_tasks (
  id uuid primary key default gen_random_uuid(),
  sequence_code text not null unique,
  user_id uuid references public.users(id) on delete cascade,
  pet_id uuid references public.pets(id) on delete set null,
  pet_snapshot jsonb not null,
  pet_photo_snapshots jsonb not null default '[]'::jsonb,
  service_type text not null,
  appointment_date date not null,
  time_window text not null,
  search_area_label text default 'Current area',
  search_area_city text,
  search_area_zip_code text,
  search_radius_miles integer not null default 10 check (search_radius_miles > 0 and search_radius_miles <= 100),
  search_uses_current_location boolean not null default true,
  search_latitude double precision,
  search_longitude double precision,
  style_goal text not null,
  special_notes text,
  reference_image_source text check (reference_image_source in ('camera', 'photo_library') or reference_image_source is null),
  reference_image_url text,
  reference_image_storage_path text,
  reference_image_file_name text,
  reference_image_mime_type text default 'image/jpeg',
  reference_image_byte_size integer check (reference_image_byte_size is null or (reference_image_byte_size >= 0 and reference_image_byte_size <= 5242880)),
  reference_image_max_bytes integer not null default 5242880 check (reference_image_max_bytes = 5242880),
  owner_hidden_score numeric check (owner_hidden_score is null or (owner_hidden_score >= 1 and owner_hidden_score <= 5)),
  owner_hidden_score_source text,
  owner_hidden_score_last_evaluated_at timestamp with time zone,
  status text default 'draft' check (status in ('draft', 'sent', 'accepted', 'cancelled', 'completed')),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

comment on table public.grooming_tasks is
  'Generated task-card data container. Stores pet profile snapshot, appointment details, reference image slot, quick lookup code, and groomer-only owner hidden score.';
comment on column public.grooming_tasks.sequence_code is
  'Internal random lookup code for groomer/admin retrieval. Do not expose in pet-owner UI or owner-facing API responses.';
comment on column public.grooming_tasks.pet_snapshot is
  'Frozen copy of the pet profile at task-card generation time, so later pet edits do not change the task request.';
comment on column public.grooming_tasks.search_radius_miles is
  'Customer-selected groomer discovery radius in miles. MVP uses city/service-area matching until real location services are connected.';
comment on column public.grooming_tasks.reference_image_byte_size is
  'Reference image upload must be 5 MB or smaller.';
comment on column public.grooming_tasks.owner_hidden_score is
  'Private groomer-visible client score derived from the previous groomer evaluation. Do not expose in pet-owner API responses or owner RLS policies.';

create table public.grooming_task_submissions (
  id uuid primary key default gen_random_uuid(),
  grooming_task_id uuid references public.grooming_tasks(id) on delete cascade,
  sequence_code text not null,
  user_id uuid references public.users(id) on delete cascade,
  groomer_id uuid references public.groomers(id) on delete cascade,
  task_snapshot jsonb not null,
  status text not null default 'sent' check (status in ('sent', 'accepted', 'declined', 'completed', 'cancelled')),
  sent_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique (grooming_task_id, groomer_id)
);

comment on table public.grooming_task_submissions is
  'A generated task card sent to a specific groomer inbox. Accepted submissions appear on the groomer schedule; declined, completed, and cancelled submissions should render as inactive where appropriate.';

create table public.grooming_task_messages (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid references public.grooming_task_submissions(id) on delete cascade,
  sender_user_id uuid references public.users(id) on delete set null,
  sender_role text not null check (sender_role in ('pet_owner', 'groomer')),
  message_text text not null default '',
  image_url text,
  created_at timestamp with time zone default now()
);

comment on column public.grooming_task_messages.image_url is
  'Optional chat image attachment. MVP demo uses local/mock references; production should store images in a private Supabase Storage bucket.';

create table public.quote_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  groomer_id uuid references public.groomers(id) on delete cascade,
  pet_id uuid references public.pets(id) on delete set null,
  service_type text,
  preferred_time text,
  notes text,
  contact_preference text,
  status text default 'submitted' check (status in ('submitted', 'viewed', 'closed')),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid references public.users(id) on delete set null,
  target_type text not null check (target_type in ('groomer', 'review', 'portfolio', 'user', 'other')),
  target_id uuid not null,
  reason text not null,
  details text,
  status text default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  admin_notes text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

create table public.ai_usage_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  feature_type text not null,
  model_name text,
  input_tokens integer,
  output_tokens integer,
  image_count integer,
  estimated_cost numeric,
  created_at timestamp with time zone default now()
);

create table public.feature_flags (
  key text primary key,
  is_enabled boolean not null default false,
  description text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

create index pets_user_id_idx on public.pets(user_id);
create index pet_photos_pet_id_idx on public.pet_photos(pet_id);
create index groomers_city_idx on public.groomers(city);
create index groomers_owner_user_id_idx on public.groomers(owner_user_id);
create index groomers_status_idx on public.groomers(status);
create index groomers_specialties_idx on public.groomers using gin(specialties);
create index groomer_portfolio_groomer_id_idx on public.groomer_portfolio(groomer_id);
create index reviews_groomer_id_idx on public.reviews(groomer_id);
create index favorites_user_id_idx on public.favorites(user_id);
create index contact_events_groomer_id_idx on public.contact_events(groomer_id);
create index contact_events_created_at_idx on public.contact_events(created_at);
create index grooming_tasks_sequence_code_idx on public.grooming_tasks(sequence_code);
create index grooming_tasks_user_id_idx on public.grooming_tasks(user_id);
create index grooming_tasks_pet_id_idx on public.grooming_tasks(pet_id);
create index grooming_tasks_status_idx on public.grooming_tasks(status);
create index grooming_task_submissions_groomer_id_idx on public.grooming_task_submissions(groomer_id);
create index grooming_task_submissions_user_id_idx on public.grooming_task_submissions(user_id);
create index grooming_task_submissions_status_idx on public.grooming_task_submissions(status);
create index grooming_task_messages_submission_id_idx on public.grooming_task_messages(submission_id);
create index quote_requests_groomer_id_idx on public.quote_requests(groomer_id);
create index reports_status_idx on public.reports(status);
create index ai_usage_logs_feature_type_idx on public.ai_usage_logs(feature_type);

create trigger set_users_updated_at before update on public.users
for each row execute function public.set_updated_at();

create trigger set_pets_updated_at before update on public.pets
for each row execute function public.set_updated_at();

create trigger set_groomers_updated_at before update on public.groomers
for each row execute function public.set_updated_at();

create trigger set_reviews_updated_at before update on public.reviews
for each row execute function public.set_updated_at();

create trigger set_grooming_tasks_updated_at before update on public.grooming_tasks
for each row execute function public.set_updated_at();

create trigger set_grooming_task_submissions_updated_at before update on public.grooming_task_submissions
for each row execute function public.set_updated_at();

create trigger set_quote_requests_updated_at before update on public.quote_requests
for each row execute function public.set_updated_at();

create trigger set_reports_updated_at before update on public.reports
for each row execute function public.set_updated_at();

create trigger set_feature_flags_updated_at before update on public.feature_flags
for each row execute function public.set_updated_at();

insert into public.feature_flags (key, is_enabled, description) values
  ('ai_pet_photo_analysis', false, 'Analyze pet photos for breed, coat, and risk hints.'),
  ('ai_pet_profile_suggestion', false, 'Suggest pet profile fields from photos and notes.'),
  ('ai_groomer_recommendation', false, 'Explain groomer matches after database filtering.'),
  ('ai_inquiry_message', false, 'Draft quote/contact messages from pet context.'),
  ('ai_review_summary', false, 'Summarize public review themes.'),
  ('ai_style_suggestion', false, 'Suggest grooming styles.'),
  ('ai_style_preview_generation', false, 'Generate preview images. Out of MVP scope.');

-- Recommended Supabase Storage buckets for the live backend:
-- pet-photos, groomer-photos, portfolio-images, review-images, task-reference-images.
-- Add RLS policies after Supabase Auth roles and admin claims are finalized.
