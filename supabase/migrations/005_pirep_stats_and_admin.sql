-- Auto-update pilot and aircraft stats when a PIREP is approved
create or replace function public.handle_pirep_approved()
returns trigger as $$
declare
  hours_decimal numeric;
begin
  -- Only run when status changes to 'approved'
  if new.status = 'approved' and (old.status is null or old.status != 'approved') then
    -- Calculate hours from block_time interval
    hours_decimal := extract(epoch from new.block_time) / 3600.0;

    -- Update pilot stats
    update pilots set
      total_flights = total_flights + 1,
      total_hours = total_hours + hours_decimal
    where id = new.pilot_id;

    -- Update aircraft stats
    update aircraft set
      total_cycles = total_cycles + 1,
      total_hours = total_hours + hours_decimal
    where id = new.aircraft_id;

    -- Auto-rank based on total hours
    update pilots set rank = case
      when total_hours >= 500 then 'Captain'
      when total_hours >= 200 then 'Senior First Officer'
      when total_hours >= 50 then 'First Officer'
      else 'Second Officer'
    end
    where id = new.pilot_id;
  end if;

  -- If status changes from 'approved' to something else, reverse the stats
  if old.status = 'approved' and new.status != 'approved' then
    hours_decimal := extract(epoch from new.block_time) / 3600.0;

    update pilots set
      total_flights = greatest(total_flights - 1, 0),
      total_hours = greatest(total_hours - hours_decimal, 0)
    where id = new.pilot_id;

    update aircraft set
      total_cycles = greatest(total_cycles - 1, 0),
      total_hours = greatest(total_hours - hours_decimal, 0)
    where id = new.aircraft_id;
  end if;

  return new;
end;
$$ language plpgsql security definer;

create trigger pirep_status_change
  after update of status on pireps
  for each row execute function public.handle_pirep_approved();

-- Admin policies: allow admins to manage all resources
-- Update pireps policy for admin review
create policy "Admins can update all pireps" on pireps for update to authenticated using (
  exists (select 1 from pilots where user_id = auth.uid() and rank = 'Admin')
);

-- Allow admins to insert/update/delete routes
create policy "Admins can manage routes" on routes for all to authenticated using (
  exists (select 1 from pilots where user_id = auth.uid() and rank = 'Admin')
);

-- Allow admins to delete aircraft
create policy "Admins can delete aircraft" on aircraft for delete to authenticated using (
  exists (select 1 from pilots where user_id = auth.uid() and rank = 'Admin')
);
