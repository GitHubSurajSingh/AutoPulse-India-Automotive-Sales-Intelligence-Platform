-- ================================================================
--  AutoPulse — Supabase SQL Schema
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


-- ── 2. SALES TABLE ──────────────────────────────────────────────
--  Stores all car sales submitted by agency staff.
--  The BI dashboard merges this with the pre-cleaned 10,000-record seed dataset.
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


-- ── 3. ROW LEVEL SECURITY ────────────────────────────────────────
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- Allow login lookups on users table (anon can check credentials)
DROP POLICY IF EXISTS "users_login" ON users;
CREATE POLICY "users_login" ON users
  FOR SELECT USING (true);

-- Allow anyone to read all sales (dashboard needs full dataset)
DROP POLICY IF EXISTS "sales_read_all" ON sales;
CREATE POLICY "sales_read_all" ON sales
  FOR SELECT USING (true);

-- Allow anyone to insert a sale (agency submits via anon key)
DROP POLICY IF EXISTS "sales_insert" ON sales;
CREATE POLICY "sales_insert" ON sales
  FOR INSERT WITH CHECK (true);


-- ── 4. HELPFUL VIEWS ────────────────────────────────────────────

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
