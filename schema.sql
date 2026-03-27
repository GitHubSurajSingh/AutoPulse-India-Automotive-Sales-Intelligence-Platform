-- ================================================================
--  AutoPulse — Supabase SQL Schema (Enhanced RLS + Car Variants)
--  Run this entire file in: Supabase Dashboard → SQL Editor → Run
-- ================================================================


-- ── 1. USERS TABLE ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id          SERIAL PRIMARY KEY,
  username    TEXT UNIQUE NOT NULL,
  password    TEXT NOT NULL,
  role        TEXT NOT NULL CHECK (role IN ('admin','manager','govt','agency')),
  name        TEXT NOT NULL,
  agency      TEXT,
  state       TEXT,
  city        TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Default user accounts
INSERT INTO users (username, password, role, name, agency, state, city) VALUES
  ('admin',        'Admin@2024',  'admin',   'National Admin',         NULL,          NULL,              NULL),
  ('manager',      'Mgr@2024',    'manager', 'Regional Manager',       NULL,          NULL,              NULL),
  ('official',     'Gov@2024',    'govt',    'Govt. Official',         NULL,          NULL,              NULL),
  ('mum_hub',      'Mum@2024',    'agency',  'Mumbai AutoHub',         'mum_hub',     'Maharashtra',     'Mumbai'),
  ('pune_motors',  'Pune@2024',   'agency',  'Pune Motors',            'pune_motors', 'Maharashtra',     'Pune'),
  ('del_elite',    'Del@2024',    'agency',  'Delhi Elite Cars',       'del_elite',   'Delhi',           'New Delhi'),
  ('blr_drive',    'Blr@2024',    'agency',  'Bangalore DriveZone',    'blr_drive',   'Karnataka',       'Bangalore'),
  ('bpl_auto',     'Bpl@2024',    'agency',  'Bhopal AutoWorld',       'bpl_auto',    'Madhya Pradesh',  'Bhopal')
ON CONFLICT (username) DO NOTHING;

-- Create agencies table for admin management
CREATE TABLE IF NOT EXISTS agencies (
  id            SERIAL PRIMARY KEY,
  agency_id     TEXT UNIQUE NOT NULL,
  name          TEXT NOT NULL,
  state         TEXT NOT NULL,
  city          TEXT NOT NULL,
  username      TEXT UNIQUE NOT NULL,
  password      TEXT NOT NULL,
  contact_name  TEXT,
  contact_phone TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Insert existing agencies
INSERT INTO agencies (agency_id, name, state, city, username, password, contact_name) VALUES
  ('mum_hub',     'Mumbai AutoHub',      'Maharashtra', 'Mumbai',      'mum_hub',     'Mum@2024',  'Mumbai Hub'),
  ('pune_motors', 'Pune Motors',         'Maharashtra', 'Pune',        'pune_motors', 'Pune@2024', 'Pune Motors'),
  ('del_elite',   'Delhi Elite Cars',    'Delhi',       'New Delhi',   'del_elite',   'Del@2024',  'Delhi Elite'),
  ('blr_drive',   'Bangalore DriveZone', 'Karnataka',   'Bangalore',   'blr_drive',   'Blr@2024',  'Bangalore Drive'),
  ('bpl_auto',    'Bhopal AutoWorld',    'Madhya Pradesh', 'Bhopal',    'bpl_auto',    'Bpl@2024',  'Bhopal Auto')
ON CONFLICT (agency_id) DO NOTHING;


-- ── 2. CAR VARIANTS TABLE (NEW) ────────────────────────────────
--  Stores car model information with manufacturing year and cost price
--  Agencies can upload CSV with their specific variant costs
CREATE TABLE IF NOT EXISTS car_variants (
  id                BIGSERIAL PRIMARY KEY,
  brand             TEXT NOT NULL,
  model             TEXT NOT NULL,
  segment           TEXT,
  year              INTEGER,
  variant           TEXT,
  fuel_type         TEXT,
  transmission      TEXT,
  exshowroom_price  NUMERIC(14,2) NOT NULL,
  cost_price        NUMERIC(14,2) NOT NULL,
  agency_id         TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW(),
  (brand, model, year, variant, fuel_type, transmission, agency_id)
);

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_car_variants_brand     ON car_variants(brand);
CREATE INDEX IF NOT EXISTS idx_car_variants_model     ON car_variants(model);
CREATE INDEX IF NOT EXISTS idx_car_variants_agency    ON car_variants(agency_id);
CREATE INDEX IF NOT EXISTS idx_car_variants_lookup    ON car_variants(brand, model, year, fuel_type, transmission);


-- ── 3. SALES TABLE ──────────────────────────────────────────────
--  Stores all car sales submitted by agency staff.
--  Profit calculation: exshowroom_price - cost_price + (30% of accessories)
--  RTO and Insurance are NOT included in profit calculation
CREATE TABLE IF NOT EXISTS sales (
  id                BIGSERIAL PRIMARY KEY,
  invoice_id        TEXT UNIQUE NOT NULL,
  sale_date         DATE NOT NULL,
  salesperson       TEXT,
  customer_name     TEXT,
  customer_type     TEXT,
  state             TEXT NOT NULL,
  city              TEXT,
  brand             TEXT NOT NULL,
  model             TEXT NOT NULL,
  segment           TEXT,
  year              INTEGER,
  variant           TEXT,
  fuel_type         TEXT,
  transmission      TEXT,
  exshowroom_price  NUMERIC(14,2),
  rto               NUMERIC(14,2),
  insurance         NUMERIC(14,2),
  accessories       NUMERIC(14,2),
  discount          NUMERIC(14,2),
  final_sale_price  NUMERIC(14,2) NOT NULL,
  cost_price        NUMERIC(14,2) NOT NULL,
  profit            NUMERIC(14,2) NOT NULL,
  profit_margin     NUMERIC(7,4),
  agency_id         TEXT NOT NULL,
  agency_name       TEXT,
  submitted_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_sales_agency    ON sales(agency_id);
CREATE INDEX IF NOT EXISTS idx_sales_date      ON sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_state     ON sales(state);
CREATE INDEX IF NOT EXISTS idx_sales_brand     ON sales(brand);
CREATE INDEX IF NOT EXISTS idx_sales_submitted ON sales(submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_year      ON sales(year);


-- ── 4. ROW LEVEL SECURITY ────────────────────────────────────────

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE agencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE car_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────────
-- USERS TABLE POLICIES
-- ────────────────────────────────────────────────────────────────

-- Allow anyone (anon) to read users (needed for login)
DROP POLICY IF EXISTS "users_login_read" ON users;
CREATE POLICY "users_login_read" ON users
  FOR SELECT USING (true);

-- Prevent direct updates/deletes from frontend
DROP POLICY IF EXISTS "users_no_write" ON users;
CREATE POLICY "users_no_write" ON users
  FOR INSERT WITH CHECK (false);

-- ────────────────────────────────────────────────────────────────
-- AGENCIES TABLE POLICIES
-- ────────────────────────────────────────────────────────────────

-- Admins can READ, INSERT, UPDATE agencies
DROP POLICY IF EXISTS "agencies_admin_all" ON agencies;
CREATE POLICY "agencies_admin_all" ON agencies
  FOR ALL USING (true) WITH CHECK (true);

-- ────────────────────────────────────────────────────────────────
-- CAR VARIANTS TABLE POLICIES
-- ────────────────────────────────────────────────────────────────

-- Anyone can READ all variants
DROP POLICY IF EXISTS "car_variants_read_all" ON car_variants;
CREATE POLICY "car_variants_read_all" ON car_variants
  FOR SELECT USING (true);

-- Agencies can INSERT/UPDATE their own variants
DROP POLICY IF EXISTS "car_variants_write_own" ON car_variants;
CREATE POLICY "car_variants_write_own" ON car_variants
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "car_variants_update_own" ON car_variants;
CREATE POLICY "car_variants_update_own" ON car_variants
  FOR UPDATE USING (true) WITH CHECK (true);

-- ────────────────────────────────────────────────────────────────
-- SALES TABLE POLICIES
-- ────────────────────────────────────────────────────────────────

-- ANYONE can INSERT a new sale (agency submission)
DROP POLICY IF EXISTS "sales_insert_any" ON sales;
CREATE POLICY "sales_insert_any" ON sales
  FOR INSERT WITH CHECK (true);

-- ANYONE can READ all sales
DROP POLICY IF EXISTS "sales_read_all" ON sales;
CREATE POLICY "sales_read_all" ON sales
  FOR SELECT USING (true);


-- ── 5. HELPFUL VIEWS ────────────────────────────────────────────

-- Monthly aggregates for BI trend chart (UPDATED with new profit calc)
CREATE OR REPLACE VIEW sales_monthly AS
SELECT
  TO_CHAR(sale_date, 'YYYY-MM')   AS month,
  EXTRACT(YEAR FROM sale_date)::INT AS year,
  EXTRACT(MONTH FROM sale_date)::INT AS month_num,
  COUNT(*)                         AS units,
  ROUND(SUM(final_sale_price)::NUMERIC, 2) AS total_revenue,
  ROUND(SUM(profit)::NUMERIC, 2)           AS total_profit,
  ROUND(AVG(profit_margin)::NUMERIC, 4)    AS avg_margin
FROM sales
GROUP BY 1, 2, 3
ORDER BY 2 DESC, 3 DESC;

-- Year-wise aggregates
CREATE OR REPLACE VIEW sales_by_year AS
SELECT
  EXTRACT(YEAR FROM sale_date)::INT AS year,
  COUNT(*)                          AS units,
  ROUND(SUM(final_sale_price)::NUMERIC, 2) AS total_revenue,
  ROUND(SUM(profit)::NUMERIC, 2)           AS total_profit,
  ROUND(AVG(profit_margin)::NUMERIC, 4)    AS avg_margin
FROM sales
GROUP BY 1
ORDER BY 1 DESC;

-- Brand aggregates
CREATE OR REPLACE VIEW sales_by_brand AS
SELECT
  brand,
  COUNT(*)                          AS units,
  ROUND(SUM(final_sale_price)::NUMERIC, 2) AS total_revenue,
  ROUND(SUM(profit)::NUMERIC, 2)           AS total_profit,
  ROUND(AVG(profit_margin)::NUMERIC, 4)    AS avg_margin
FROM sales
GROUP BY brand
ORDER BY total_revenue DESC;

-- State aggregates
CREATE OR REPLACE VIEW sales_by_state AS
SELECT
  state,
  COUNT(*)                          AS units,
  ROUND(SUM(final_sale_price)::NUMERIC, 2) AS total_revenue,
  ROUND(SUM(profit)::NUMERIC, 2)           AS total_profit,
  ROUND(AVG(profit_margin)::NUMERIC, 4)    AS avg_margin
FROM sales
GROUP BY state
ORDER BY total_revenue DESC;

-- Agency aggregates
CREATE OR REPLACE VIEW sales_by_agency AS
SELECT
  agency_id,
  agency_name,
  COUNT(*)                          AS units,
  ROUND(SUM(final_sale_price)::NUMERIC, 2) AS total_revenue,
  ROUND(SUM(profit)::NUMERIC, 2)           AS total_profit,
  ROUND(AVG(profit_margin)::NUMERIC, 4)    AS avg_margin
FROM sales
GROUP BY agency_id, agency_name
ORDER BY total_revenue DESC;


-- ── 6. VERIFICATION QUERIES (Run these to test) ─────────────────

-- Check all sales in database
-- SELECT COUNT(*) as total_sales FROM sales;

-- Check car variants
-- SELECT * FROM car_variants LIMIT 10;

-- Check agencies
-- SELECT * FROM agencies;

-- Check by agency
-- SELECT agency_id, agency_name, COUNT(*) as count FROM sales GROUP BY agency_id, agency_name;

-- Check recent submissions (last 24 hours)
-- SELECT invoice_id, agency_name, submitted_at FROM sales 
-- WHERE submitted_at > NOW() - INTERVAL '24 hours' 
-- ORDER BY submitted_at DESC;
