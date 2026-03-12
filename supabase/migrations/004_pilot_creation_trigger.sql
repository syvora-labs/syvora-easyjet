-- Create pilot profile via a trigger on auth.users using raw_user_meta_data
-- This runs as SECURITY DEFINER so it bypasses RLS

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.pilots (user_id, callsign, first_name, last_name, hub)
  values (
    new.id,
    new.raw_user_meta_data->>'callsign',
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    coalesce(new.raw_user_meta_data->>'hub', 'LSGG')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
