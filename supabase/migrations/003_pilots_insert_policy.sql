-- Allow authenticated users to insert their own pilot profile
create policy "Pilots can insert own profile" on pilots for insert to authenticated with check (auth.uid() = user_id);
