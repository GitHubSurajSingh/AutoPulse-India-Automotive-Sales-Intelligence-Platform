-- ================================================================
--  AutoPulse — Supabase SQL Schema (Enhanced with Car Variants)
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


-- ── 2. CAR_VARIANTS TABLE (NEW) ─────────────────────────────────
--  Stores car model information with manufacturing year and cost price
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
  UNIQUE(brand, model, year, variant)
);

CREATE INDEX IF NOT EXISTS idx_car_variants_brand ON car_variants(brand);
CREATE INDEX IF NOT EXISTS idx_car_variants_agency ON car_variants(agency_id);


-- ── 3. SALES TABLE ──────────────────────────────────────────────
--  Stores all car sales submitted by agency staff.
--  Profit calculation: profit = final_sale_price - cost_price
--  Profit margin = (profit / (final_sale_price - rto - insurance)) * 100
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
  cost_price        NUMERIC(14,2),
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


-- ── 4. ROW LEVEL SECURITY ────────────────────────────────────────

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE car_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────────
-- USERS TABLE POLICIES
-- ────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "users_login_read" ON users;
CREATE POLICY "users_login_read" ON users
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "users_no_write" ON users;
CREATE POLICY "users_no_write" ON users
  FOR INSERT WITH CHECK (false);


-- ────────────────────────────────────────────────────────────────
-- CAR_VARIANTS TABLE POLICIES
-- ────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "car_variants_insert_agency" ON car_variants;
CREATE POLICY "car_variants_insert_agency" ON car_variants
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "car_variants_read_all" ON car_variants;
CREATE POLICY "car_variants_read_all" ON car_variants
  FOR SELECT USING (true);


-- ────────────────────────────────────────────────────────────────
-- SALES TABLE POLICIES
-- ────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "sales_insert_any" ON sales;
CREATE POLICY "sales_insert_any" ON sales
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "sales_read_all" ON sales;
CREATE POLICY "sales_read_all" ON sales
  FOR SELECT USING (true);


-- ── 5. VIEWS ────────────────────────────────────────────────────

-- Monthly aggregates for BI trend chart
CREATE OR REPLACE VIEW sales_monthly AS
SELECT
  TO_CHAR(sale_date, 'YYYY-MM')   AS month,
  COUNT(*)                         AS units,
  ROUND(SUM(final_sale_price)::NUMERIC, 2) AS total_revenue,
  ROUND(SUM(profit)::NUMERIC, 2)           AS total_profit,
  ROUND(AVG(profit_margin)::NUMERIC, 4)    AS avg_margin
FROM sales
GROUP BY 1
ORDER BY 1;

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
