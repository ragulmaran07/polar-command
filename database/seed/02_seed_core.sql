-- =========================================================
-- POLAR COMMAND — Phase 1 Seed Data
-- Demo users + reference locations + one sample expedition
-- =========================================================

-- Demo users (passwords documented in README — BCrypt hashed here)
INSERT INTO users (id, full_name, email, phone, password_hash, role_id, organization, is_active)
VALUES
 ('11111111-1111-1111-1111-111111111111', 'Admin User', 'admin@polarcommand.com', '+91-9000000001',
   '$2b$10$WoJsVwkMVDsgKg.fw6C9M.Py5fciCbooVYAeJcPBSgxx3Gq/z8lEe',
   (SELECT id FROM roles WHERE name = 'ADMIN'), 'NCPOR', TRUE),

 ('22222222-2222-2222-2222-222222222222', 'Logistics Officer', 'logistics@polarcommand.com', '+91-9000000002',
   '$2b$10$l8yDMzA3ymrxCPIySFDxEec3KSHkRAgk9JVkah2MqtM0EYmr5pzY2',
   (SELECT id FROM roles WHERE name = 'LOGISTICS_OFFICER'), 'NCPOR', TRUE),

 ('33333333-3333-3333-3333-333333333333', 'Dr. Kumar (Expedition Leader)', 'leader@polarcommand.com', '+91-9000000003',
   '$2b$10$hK00GtVN.Nzdj.cWwgM61uMOG81RmUKnSnlgPqf82xqenubtkDCXC',
   (SELECT id FROM roles WHERE name = 'EXPEDITION_LEADER'), 'NCPOR', TRUE),

 ('44444444-4444-4444-4444-444444444444', 'Field Staff Member', 'field@polarcommand.com', '+91-9000000004',
   '$2b$10$mLKZ1egLeU5rv6xgrY.LqO63xsn08nBuXUDLQB8nh9mmELlbwRXqK',
   (SELECT id FROM roles WHERE name = 'FIELD_STAFF'), 'NCPOR', TRUE);

-- Reference locations (simulated coordinates, real-world approximate positions)
INSERT INTO locations (id, name, type, latitude, longitude, description, is_simulated) VALUES
 ('a1111111-0000-0000-0000-000000000001', 'Bharati Research Station', 'RESEARCH_STATION', -69.4067, 76.1897, 'Indian Antarctic research station', TRUE),
 ('a1111111-0000-0000-0000-000000000002', 'Maitri Research Station', 'RESEARCH_STATION', -70.7660, 11.7333, 'Indian Antarctic research station', TRUE),
 ('a1111111-0000-0000-0000-000000000003', 'Field Camp Alpha', 'FIELD_CAMP', -69.55, 76.35, 'Glaciology field camp near Bharati', TRUE),
 ('a1111111-0000-0000-0000-000000000004', 'Field Camp B', 'FIELD_CAMP', -70.9, 11.9, 'Field camp near Maitri', TRUE),
 ('a1111111-0000-0000-0000-000000000005', 'MV Polar Voyager (Ship)', 'SHIP', -55.0, 70.0, 'Expedition supply and transport vessel', TRUE),
 ('a1111111-0000-0000-0000-000000000006', 'Cape Town Port', 'PORT', -33.9249, 18.4241, 'Departure port for Antarctic logistics', TRUE),
 ('a1111111-0000-0000-0000-000000000007', 'NCPOR Warehouse, Goa', 'WAREHOUSE', 15.4909, 73.8278, 'Primary staging warehouse in India', TRUE);

-- Sample expedition for the SIH demo scenario
INSERT INTO expeditions (id, expedition_code, name, year, start_date, end_date, destination, research_station_id, leader_id, status, description)
VALUES
 ('b2222222-0000-0000-0000-000000000001', 'EXP-2027-01', 'Antarctic Scientific Expedition 2027', 2027,
   '2027-01-05', '2027-03-20', 'Bharati Research Station',
   'a1111111-0000-0000-0000-000000000001',
   '33333333-3333-3333-3333-333333333333',
   'ACTIVE',
   'Flagship demo expedition used for the Polar Command demonstration scenario.');