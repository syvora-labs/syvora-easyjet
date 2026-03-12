-- Allow admins to update and delete any pilot
create policy "Admins can update all pilots" on pilots for update to authenticated using (
  exists (select 1 from pilots where user_id = auth.uid() and rank = 'Admin')
);

create policy "Admins can delete pilots" on pilots for delete to authenticated using (
  exists (select 1 from pilots where user_id = auth.uid() and rank = 'Admin')
);
