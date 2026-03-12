-- EasyJet Switzerland Virtual - Initial Schema

-- Pilots table
create table pilots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  callsign text unique not null,
  first_name text not null,
  last_name text not null,
  rank text not null default 'First Officer',
  hub text not null default 'LSGG',
  total_hours numeric(10,2) not null default 0,
  total_flights integer not null default 0,
  joined_at timestamptz not null default now(),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Fleet / Aircraft table
create table aircraft (
  id uuid primary key default gen_random_uuid(),
  registration text unique not null,
  type text not null,
  icao_type text not null,
  livery text not null default 'EasyJet Switzerland',
  total_hours numeric(10,2) not null default 0,
  total_cycles integer not null default 0,
  status text not null default 'active' check (status in ('active', 'maintenance', 'retired')),
  home_base text not null default 'LSGG',
  seat_capacity integer not null default 186,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Routes table
create table routes (
  id uuid primary key default gen_random_uuid(),
  flight_number text not null,
  departure_icao text not null,
  departure_name text not null,
  arrival_icao text not null,
  arrival_name text not null,
  distance_nm integer not null,
  estimated_time interval not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Bookings table
create table bookings (
  id uuid primary key default gen_random_uuid(),
  pilot_id uuid references pilots(id) on delete cascade not null,
  route_id uuid references routes(id) on delete restrict not null,
  aircraft_id uuid references aircraft(id) on delete restrict not null,
  flight_number text not null,
  departure_icao text not null,
  arrival_icao text not null,
  scheduled_departure timestamptz not null,
  status text not null default 'booked' check (status in ('booked', 'flying', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- PIREPs (Pilot Reports / Flight Logs)
create table pireps (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references bookings(id) on delete set null,
  pilot_id uuid references pilots(id) on delete cascade not null,
  aircraft_id uuid references aircraft(id) on delete restrict not null,
  flight_number text not null,
  departure_icao text not null,
  arrival_icao text not null,
  departure_time timestamptz not null,
  arrival_time timestamptz not null,
  block_time interval not null,
  flight_time interval not null,
  distance_nm integer not null,
  fuel_used integer, -- lbs
  passengers integer,
  landing_rate integer, -- fpm (negative)
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  remarks text,
  created_at timestamptz not null default now()
);

-- Indexes
create index idx_pilots_user_id on pilots(user_id);
create index idx_bookings_pilot_id on bookings(pilot_id);
create index idx_bookings_status on bookings(status);
create index idx_pireps_pilot_id on pireps(pilot_id);
create index idx_pireps_status on pireps(status);
create index idx_aircraft_status on aircraft(status);
create index idx_routes_active on routes(is_active);

-- Row Level Security
alter table pilots enable row level security;
alter table aircraft enable row level security;
alter table routes enable row level security;
alter table bookings enable row level security;
alter table pireps enable row level security;

-- Policies: pilots can read all, insert their own, update their own
create policy "Pilots are viewable by everyone" on pilots for select using (true);
create policy "Pilots can insert own profile" on pilots for insert to authenticated with check (auth.uid() = user_id);
create policy "Pilots can update own profile" on pilots for update using (auth.uid() = user_id);

-- Aircraft: readable by all authenticated
create policy "Aircraft viewable by authenticated" on aircraft for select to authenticated using (true);
create policy "Aircraft managed by admins" on aircraft for all using (
  exists (select 1 from pilots where user_id = auth.uid() and rank = 'Admin')
);

-- Routes: readable by all authenticated
create policy "Routes viewable by authenticated" on routes for select to authenticated using (true);

-- Bookings: pilots see all, manage own
create policy "Bookings viewable by authenticated" on bookings for select to authenticated using (true);
create policy "Pilots manage own bookings" on bookings for insert to authenticated with check (
  pilot_id in (select id from pilots where user_id = auth.uid())
);
create policy "Pilots update own bookings" on bookings for update to authenticated using (
  pilot_id in (select id from pilots where user_id = auth.uid())
);

-- PIREPs: pilots see all, manage own
create policy "PIREPs viewable by authenticated" on pireps for select to authenticated using (true);
create policy "Pilots manage own pireps" on pireps for insert to authenticated with check (
  pilot_id in (select id from pilots where user_id = auth.uid())
);

-- Updated_at trigger function
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger pilots_updated_at before update on pilots for each row execute function update_updated_at();
create trigger aircraft_updated_at before update on aircraft for each row execute function update_updated_at();
create trigger bookings_updated_at before update on bookings for each row execute function update_updated_at();
