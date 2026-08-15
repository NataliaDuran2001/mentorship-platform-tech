-- UI/AI language the student picked in Settings. Defaults to 'en': the
-- app's original baseline was all-English, so existing rows keep behaving
-- exactly as before until the student switches it.
alter table public.profiles
  add column language text not null default 'en'
  check (language in ('es', 'en'));
