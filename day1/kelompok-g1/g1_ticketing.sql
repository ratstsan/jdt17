-- ==========================================
-- 1. Create Enums (Must be created first)
-- ==========================================
CREATE TYPE ticket_status AS ENUM (
    'available', 
    'reserved', 
    'sold'
);

CREATE TYPE queue_status AS ENUM (
    'waiting', 
    'processing', 
    'completed', 
    'failed'
);

-- ==========================================
-- 2. Create Tables
-- ==========================================

-- Users Table: Stores participant accounts
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    password_hash VARCHAR NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ticket Tiers Table: Manages seat categories, quotas, and pricing
CREATE TABLE ticket_tiers (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    price INT NOT NULL,
    capacity INT NOT NULL
);

-- Ticket Table: Individual physical/digital tickets
CREATE TABLE ticket (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_code VARCHAR UNIQUE NOT NULL,
    tier_id VARCHAR REFERENCES ticket_tiers(id),
    user_id UUID REFERENCES users(id),
    status ticket_status DEFAULT 'available',
    reserved_until TIMESTAMP,
    ticket_url TEXT
);

-- Queue Transactions Table: Tracks the "war" process and live queue
CREATE TABLE queue_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    tier_id VARCHAR NOT NULL REFERENCES ticket_tiers(id),
    ticket_id UUID REFERENCES ticket(id),
    platform VARCHAR NOT NULL,
    status queue_status DEFAULT 'waiting',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 3. Create Indexes (For Performance)
-- ==========================================
-- Adding an index to queue_sessions to make finding the oldest 'waiting' person lightning fast
CREATE INDEX idx_queue_sessions_status_joined ON queue_sessions(status, joined_at);

-- Adding an index to the ticket table to quickly look up available tickets by tier
CREATE INDEX idx_ticket_tier_status ON ticket(tier_id, status);



-- ================================================================================================================


-- Function 1: Generates a random alphanumeric string of a specified length
CREATE OR REPLACE FUNCTION generate_random_string(length INT) 
RETURNS VARCHAR AS $$
DECLARE
  chars VARCHAR := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ23456789'; 
  result VARCHAR := '';
  i INT := 0;
BEGIN
  FOR i IN 1..length LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::INT, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function 2: Formats the random string with your Tier prefix
CREATE OR REPLACE FUNCTION generate_ticket_code(prefix VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
  -- Example output: 'VIP-1-7X9P-A2M4-L9Q1'
  RETURN prefix || '-' || 
         generate_random_string(4) || '-' || 
         generate_random_string(4) || '-' || 
         generate_random_string(4);
END;
$$ LANGUAGE plpgsql;


-- 3 Function 3: CREATE REPORT VIEW (Modul Live Dashboard)
CREATE OR REPLACE VIEW report_view AS
-- 1. Hitung metrik antrean dari tabel queue_sessions
WITH queue_metrics AS (
    SELECT 
        tier_id,
        COUNT(CASE WHEN platform = 'Mobile' AND status = 'waiting' THEN 1 END) AS antrean_mobile,
        COUNT(CASE WHEN platform = 'Web' AND status = 'waiting' THEN 1 END) AS antrean_web,
        COUNT(CASE WHEN status = 'waiting' THEN 1 END) AS total_antrean
    FROM queue_sessions
    GROUP BY tier_id
),

-- 2. Hitung metrik stok tiket dari tabel ticket
ticket_metrics AS (
    SELECT 
        tier_id,
        COUNT(CASE WHEN status = 'available' THEN 1 END) AS sisa_tiket,
        COUNT(CASE WHEN status = 'reserved' THEN 1 END) AS sedang_dibayar,
        COUNT(CASE WHEN status = 'sold' THEN 1 END) AS tiket_terjual
    FROM ticket
    GROUP BY tier_id
)

-- 3. Gabungkan semuanya ke dalam satu Dashboard Utama
SELECT 
    tt.name AS "Kategori Seat / Tier",
    tt.capacity AS "Kapasitas Maksimal",
    
    -- Status Tiket (Pakai COALESCE agar jika kosong tampil 0, bukan NULL)
    COALESCE(tm.sisa_tiket, 0) AS "Sisa Tiket (Available)",
    COALESCE(tm.sedang_dibayar, 0) AS "Sedang Dibayar (Reserved)",
    COALESCE(tm.tiket_terjual, 0) AS "Tiket Terjual (Sold)",
    
    -- Status Trafik Antrean
    COALESCE(qm.antrean_mobile, 0) AS "Antrean Mobile",
    COALESCE(qm.antrean_web, 0) AS "Antrean Web",
    COALESCE(qm.total_antrean, 0) AS "Total Antrean (Waiting)"
FROM 
    ticket_tiers tt
LEFT JOIN queue_metrics qm ON tt.id = qm.tier_id
LEFT JOIN ticket_metrics tm ON tt.id = tm.tier_id
ORDER BY 
    tt.name ASC;

	
-- ==========================================================================================================



-- 1. Insert Ticket Tiers
INSERT INTO ticket_tiers (id, name, price, capacity) VALUES 
('FST', 'Festival General Admission', 1500000, 5000),
('VIP-1', 'VIP Front Row', 3500000, 500),
('VIP-2', 'VIP Middle', 2500000, 1000);

-- 2. Insert Dummy Users
INSERT INTO users (username, email, password_hash) VALUES 
('Kenzie', 'kenzie@example.com', 'hashed_password_123'),
('Verry', 'verry@example.com', 'hashed_password_456'),
('Rio', 'rio@example.com', 'hashed_password_789'),
('Edi', 'edi@example.com', 'hashed_001');

-- 3. Pre-generate Available Tickets (Using the stored procedure!)
-- In a real system, you would run a loop to generate all 6,500 tickets.
INSERT INTO ticket (ticket_code, tier_id, status) VALUES 
(generate_ticket_code('VIP-1'), 'VIP-1', 'available'),
(generate_ticket_code('VIP-1'), 'VIP-1', 'available'),
(generate_ticket_code('FST'), 'FST', 'available'),
(generate_ticket_code('VIP-2'), 'VIP-2', 'available'),
(generate_ticket_code('VIP-2'), 'VIP-2', 'available'),
(generate_ticket_code('FST'), 'FST', 'available');


-- Login
-- Simulasi Kenzie melakukan Login ke sistem
SELECT id, username, email 
FROM users 
WHERE email = 'kenzie@example.com' AND password_hash = 'hashed_password_123';

-- Tampilkan dashboard sebelum war dimulai
SELECT * FROM report_view;

-- 4. Insert Users into the Queue (Simulating the "War") -- Users clicks "buy ticket"
-- We use subqueries here to grab the UUIDs of the users we just created.
INSERT INTO queue_sessions (user_id, tier_id, platform, status) VALUES 
((SELECT id FROM users WHERE username = 'Kenzie'), 'VIP-1', 'Mobile', 'waiting'),
((SELECT id FROM users WHERE username = 'Rio'), 'VIP-1', 'Web', 'waiting'),
((SELECT id FROM users WHERE username = 'Verry'), 'FST', 'Mobile', 'waiting'),
((SELECT id FROM users WHERE username = 'Edi'), 'FST', 'Mobile', 'waiting');


SELECT * FROM report_view;

-- =============================================================================================================
-- After queue inserted, the user screen frontend displays a "waiting" or "loading"
-- While that happens, this is what the server do:

-- This begins a strict transaction block
BEGIN;

-- STEP 1: Grab the absolute oldest person waiting, no matter the tier
WITH next_in_line AS (
    SELECT id AS session_id, user_id, tier_id -- Notice we grab their tier_id here!
    FROM queue_sessions 
    WHERE status = 'waiting'
    ORDER BY joined_at ASC 
    LIMIT 1 
    FOR UPDATE SKIP LOCKED
),

-- STEP 2: Find a ticket that matches whatever tier they requested in Step 1
available_ticket AS (
    SELECT id AS locked_ticket_id 
    FROM ticket 
    WHERE tier_id = (SELECT tier_id FROM next_in_line) -- Dynamic matching!
      AND status = 'available'
    LIMIT 1 
    FOR UPDATE SKIP LOCKED
),

-- STEP 3: Reserve the ticket
update_ticket AS (
    UPDATE ticket 
    SET 
        status = 'reserved',
        user_id = (SELECT user_id FROM next_in_line),
        reserved_until = NOW() + INTERVAL '5 minutes'
    WHERE id = (SELECT locked_ticket_id FROM available_ticket)
    RETURNING id
)

-- STEP 4: Update the queue session
UPDATE queue_sessions 
SET 
    status = 'processing',
    ticket_id = (SELECT id FROM update_ticket)
WHERE id = (SELECT session_id FROM next_in_line);

COMMIT;
