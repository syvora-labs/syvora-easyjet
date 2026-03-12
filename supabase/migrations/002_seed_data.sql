-- Seed data for EasyJet Switzerland Virtual

-- Fleet
insert into aircraft (registration, type, icao_type, livery, home_base, seat_capacity) values
  ('HB-JXA', 'Airbus A320-214', 'A320', 'EasyJet Switzerland', 'LSGG', 186),
  ('HB-JXB', 'Airbus A320-214', 'A320', 'EasyJet Switzerland', 'LSGG', 186),
  ('HB-JXC', 'Airbus A320-214', 'A320', 'EasyJet Switzerland', 'LSZH', 186),
  ('HB-JXD', 'Airbus A320-214', 'A320', 'EasyJet Switzerland', 'LSZH', 186),
  ('HB-JXE', 'Airbus A320neo', 'A20N', 'EasyJet Switzerland', 'LSGG', 194),
  ('HB-JXF', 'Airbus A320neo', 'A20N', 'EasyJet Switzerland', 'LSGG', 194),
  ('HB-JXG', 'Airbus A321neo', 'A21N', 'EasyJet Switzerland', 'LSGG', 235),
  ('HB-JXH', 'Airbus A319-111', 'A319', 'EasyJet Switzerland', 'LSBS', 156),
  ('HB-JXI', 'Airbus A319-111', 'A319', 'EasyJet Switzerland', 'LSBS', 156),
  ('HB-JXJ', 'Airbus A320neo', 'A20N', 'EasyJet Switzerland', 'LSZH', 194);

-- Routes from Geneva (LSGG)
insert into routes (flight_number, departure_icao, departure_name, arrival_icao, arrival_name, distance_nm, estimated_time) values
  ('EZS1401', 'LSGG', 'Geneva', 'EGLL', 'London Heathrow', 404, '1:30:00'),
  ('EZS1403', 'LSGG', 'Geneva', 'EGKK', 'London Gatwick', 393, '1:25:00'),
  ('EZS1421', 'LSGG', 'Geneva', 'LFPG', 'Paris CDG', 243, '1:00:00'),
  ('EZS1441', 'LSGG', 'Geneva', 'LEBL', 'Barcelona', 390, '1:25:00'),
  ('EZS1451', 'LSGG', 'Geneva', 'LIRF', 'Rome Fiumicino', 367, '1:20:00'),
  ('EZS1461', 'LSGG', 'Geneva', 'LEPA', 'Palma de Mallorca', 428, '1:35:00'),
  ('EZS1471', 'LSGG', 'Geneva', 'LPPT', 'Lisbon', 801, '2:30:00'),
  ('EZS1481', 'LSGG', 'Geneva', 'EDDB', 'Berlin', 433, '1:30:00'),
  ('EZS1491', 'LSGG', 'Geneva', 'LGAV', 'Athens', 910, '2:45:00'),
  ('EZS1501', 'LSGG', 'Geneva', 'LTFM', 'Istanbul', 1050, '3:00:00');

-- Routes from Zurich (LSZH)
insert into routes (flight_number, departure_icao, departure_name, arrival_icao, arrival_name, distance_nm, estimated_time) values
  ('EZS1601', 'LSZH', 'Zurich', 'EGLL', 'London Heathrow', 427, '1:35:00'),
  ('EZS1611', 'LSZH', 'Zurich', 'LEBL', 'Barcelona', 468, '1:40:00'),
  ('EZS1621', 'LSZH', 'Zurich', 'LFPG', 'Paris CDG', 270, '1:05:00'),
  ('EZS1631', 'LSZH', 'Zurich', 'LIMC', 'Milan Malpensa', 136, '0:50:00'),
  ('EZS1641', 'LSZH', 'Zurich', 'LOWW', 'Vienna', 324, '1:10:00');

-- Routes from Basel (LSBS)
insert into routes (flight_number, departure_icao, departure_name, arrival_icao, arrival_name, distance_nm, estimated_time) values
  ('EZS1701', 'LSBS', 'Basel', 'EGKK', 'London Gatwick', 365, '1:20:00'),
  ('EZS1711', 'LSBS', 'Basel', 'LEPA', 'Palma de Mallorca', 480, '1:45:00'),
  ('EZS1721', 'LSBS', 'Basel', 'LGAV', 'Athens', 870, '2:40:00');
