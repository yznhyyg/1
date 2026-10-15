-- Run once in the Supabase SQL editor for the player_settings table.
-- The game keeps one row per user and counts distinct calendar login days.
alter table public.player_settings
  add column if not exists login_days integer not null default 0;

alter table public.player_settings
  add column if not exists last_login_date date;
