# AutoPulse 🚗📊
### India Automotive Sales Intelligence Platform

> A role-based, real-time BI dashboard system for India's automotive sector. Car agencies submit sales data, and managers + government officials get instant analytics across the entire cleaned dataset — with zero data crossover between roles.

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Netlify-00C7B7?style=flat-square&logo=netlify)](https://autopulse-demo.netlify.app)
[![Dataset](https://img.shields.io/badge/Dataset-10%2C000%20Records-f4793b?style=flat-square)](./seed_data.js)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](./LICENSE)
[![Supabase](https://img.shields.io/badge/Database-Supabase%20PostgreSQL-3ECF8E?style=flat-square&logo=supabase)](https://supabase.com)

---

## 📌 The Problem

India's automotive dealership ecosystem suffers from **fragmented, siloed sales intelligence**:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CURRENT SITUATION                            │
│                                                                     │
│  Agency A ──► Excel Sheet    ←── No visibility to others           │
│  Agency B ──► WhatsApp CSV   ←── Manual, error-prone               │
│  Agency C ──► Paper records  ←── Weeks-old data                    │
│                                                                     │
│  Regional Manager ──► "Can I see total SUV sales in Delhi?"         │
│                       ❌ No. You'd have to call each agency.        │
│                                                                     │
│  Govt. Official   ──► "What's the EV adoption rate in MP?"          │
│                       ❌ No. Wait 3 months for a compiled report.   │
└─────────────────────────────────────────────────────────────────────┘
```

**Core pain points:**
- 🔴 Agencies use spreadsheets — no central database
- 🔴 Managers wait weeks for aggregated reports
- 🔴 Government officials have no real-time oversight
- 🔴 No way to drill into brand, segment, fuel, or regional trends
- 🔴 Agency A can accidentally see Agency B's client data
- 🔴 Zero pricing standardization — RTO, insurance calculated inconsistently

---

## ✅ The Solution

**AutoPulse** is a zero-infrastructure, browser-based platform with **strict role separation**:

```
┌─────────────────────────────────────────────────────────────────────┐
│                       AUTOPULSE SOLUTION                            │
│                                                                     │
│  ┌──────────────┐    submits    ┌──────────────────┐               │
│  │ Agency Staff │──────────────►│  Supabase DB     │               │
│  │  (agency.html)│              │  (PostgreSQL)    │               │
│  │  sees: OWN   │              │                  │               │
│  │  records only│              │  + 10K seed rows │               │
│  └──────────────┘              └────────┬─────────┘               │
│                                         │ merged                   │
│                                         ▼                           │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │              dashboard.html (role-gated)                     │  │
│  │                                                              │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌────────────────────┐  │  │
│  │  │ National    │  │  Regional   │  │   Govt. Official   │  │  │
│  │  │   Admin     │  │  Manager    │  │   (read-only)      │  │  │
│  │  │ Full access │  │ Analytics + │  │  Analytics only    │  │  │
│  │  │ + admin     │  │ transactions│  │  + transactions    │  │  │
│  │  └─────────────┘  └─────────────┘  └────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ System Architecture

```
autopulse/
│
├── index.html          ← Login & role routing
│     └── Routes to agency.html OR dashboard.html based on role
│
├── agency.html         ← Agency staff portal
│     ├── Sale entry form (auto-calculates RTO, insurance, profit)
│     ├── "My Records" — shows ONLY that agency's transactions
│     └── "My Summary" — brand breakdown for that agency only
│
├── dashboard.html      ← BI analytics (manager / govt / admin)
│     ├── Overview     — KPIs + interactive cross-filtering charts
│     ├── Brands       — Revenue, margin, heatmap
│     ├── Geography    — State drill-down
│     ├── Transactions — All 10K records + live, full filter+sort
│     └── Admin Panel  — User management (admin only)
│
├── app.js              ← Shared core: Auth, DB, Refresh, Toast, fmt
│
├── seed_data.js        ← All 10,000 CSV rows as JS array (3.4MB)
│                          Loaded client-side; no server needed
│
└── schema.sql          ← Supabase SQL: tables, RLS policies, views
```

---

## 🔄 Data Flow Diagram

```
                     ┌─────────────────────────┐
                     │     Car Agency Staff     │
                     │    (agency role login)   │
                     └────────────┬────────────┘
                                  │ fills form
                                  ▼
┌─────────────────────────────────────────────────┐
│              agency.html — Sale Form            │
│                                                 │
│  Brand + Model + Fuel + Transmission            │
│       ↓                                         │
│  Ex-Showroom Price (entered)                    │
│       ↓ auto-computed                           │
│  RTO        = ExShowroom × 10.5%               │
│  Insurance  = ExShowroom × 3.2%                │
│  Final Price= ExShowroom + RTO + Ins + Acc - Disc│
│  Cost Price = Final × 87%                      │
│  Profit     = Final - Cost                     │
│  Margin %   = (Profit / Final) × 100           │
└───────────────────────┬─────────────────────────┘
                        │ DB.insertSale()
                        ▼
              ┌──────────────────┐
              │   Supabase DB    │◄── If configured
              │   `sales` table  │
              └────────┬─────────┘
                       │ (localStorage fallback if no Supabase)
                       │
          ┌────────────┴──────────────────────────┐
          │                                        │
          ▼                                        ▼
┌──────────────────────┐             ┌──────────────────────────┐
│  Agency sees:        │             │   Dashboard sees:         │
│  • Own records only  │             │   • 10,000 seed rows      │
│  • Filtered by       │             │   • + ALL live agency     │
│    their agency_id   │             │     submissions merged    │
│  • No cross-agency   │             │   • Full filters + sort   │
│    visibility        │             │   • Interactive charts    │
└──────────────────────┘             │   • CSV export            │
                                     │   • 24h auto-refresh      │
                                     └──────────────────────────┘
```

---

## 👥 Role Matrix

| Role | Portal | View BI Charts | All Transactions | Submit Sales | Own Records | Admin |
|------|--------|---------------|-----------------|-------------|-------------|-------|
| **Admin** | Dashboard | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Manager** | Dashboard | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Govt. Official** | Dashboard | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Agency Staff** | Agency Portal | ❌ | ❌ | ✅ | ✅ | ❌ |

---


## 🔑 Default Credentials

### Analytics Roles (access `dashboard.html`)
| Username | Password | Role | Permissions |
|----------|----------|------|-------------|
| `admin` | `Admin@2024` | Admin | Full access + admin panel |
| `manager` | `Mgr@2024` | Manager | BI analytics, all transactions |
| `official` | `Gov@2024` | Govt | Read-only analytics |

### Agency Roles (access `agency.html`)
| Username | Password | Agency | Location |
|----------|----------|--------|----------|
| `mum_hub` | `Mum@2024` | Mumbai AutoHub | Maharashtra · Mumbai |
| `pune_motors` | `Pune@2024` | Pune Motors | Maharashtra · Pune |
| `del_elite` | `Del@2024` | Delhi Elite Cars | Delhi · New Delhi |
| `blr_drive` | `Blr@2024` | Bangalore DriveZone | Karnataka · Bangalore |
| `bpl_auto` | `Bpl@2024` | Bhopal AutoWorld | Madhya Pradesh · Bhopal |

---

## 📊 Dashboard Features

### Overview Page
- **4 KPI cards** — Total Revenue, Profit, Avg Price/Unit, Avg Profit/Unit
- **Global filter bar** — Filter entire dashboard by State, Brand, Segment, Fuel, Customer Type simultaneously
- **Interactive charts** — Click a donut segment to cross-filter; click a bar to drill down
- **Trend chart** — Toggle Revenue / Profit / Both view
- **Auto-refresh countdown** — 24-hour cycle with manual override

### Brand Analysis
- Brand scorecards with revenue and margin
- Horizontal bar chart — click to filter overview by brand
- Radar chart — margin comparison
- **State × Brand heatmap** — hover to enlarge cells

### Geography
- State KPI cards (4 states)
- Grouped bar chart — click state to filter overview
- Donut — unit share
- Detailed table with progress bars

### Transactions Page
**11 simultaneous filters:**
- State, Brand, Segment, Fuel, Transmission, Customer Type
- Date range (from / to)
- Price range (min ₹ / max ₹)
- Full-text search (invoice, salesperson, brand, city, model)

**Sortable columns** (click header to sort ↑↓):
Invoice · Date · State · City · Salesperson · Customer · Brand · Model · Transmission · Ex-Showroom · Final Price · Profit · Margin

**Pagination:** 25 / 50 / 100 / 250 / 500 rows per page

**Export:** Filtered + sorted result as timestamped `.csv`

**Source column:** Shows whether each row is `Seed` (from original dataset) or `Live` (agency submission)

---

## 💰 Auto-Calculation Logic (Agency Form)

```
Ex-Showroom Price      (entered by agency)
  + RTO               = ExShowroom × 10.5%
  + Insurance         = ExShowroom × 3.2%
  + Accessories       (entered, optional)
  - Discount          (entered, optional)
  ─────────────────────────────────────────
  = Final Sale Price  (auto-computed)

Cost Price            = Final × 87%  (87% industry cost ratio)
Profit                = Final − Cost
Profit Margin %       = (Profit / Final) × 100
```

---

## 🗂️ Dataset

The `seed_data.js` file contains **10,000 real-world structured records** from India's automotive market:

| Field | Values |
|-------|--------|
| **States** | Delhi, Maharashtra, Karnataka, Madhya Pradesh |
| **Cities** | Mumbai, Pune, Nagpur, New Delhi, Bangalore, Mysore, Bhopal, Indore, Jabalpur |
| **Brands** | Honda, Hyundai, Kia, MG, Mahindra, Maruti Suzuki, Tata, Toyota |
| **Models** | City, Creta, i20, Seltos, Hector, Scorpio-N, XUV700, Baleno, Brezza, Swift, Nexon, Punch, Innova Crysta |
| **Segments** | SUV (55%), Hatchback (21%), MPV (11%), Sedan (13%) |
| **Fuels** | Petrol, Diesel, Electric, CNG (roughly equal split) |
| **Date Range** | Feb 2024 – Feb 2026 |
| **Total Revenue** | ₹17.18 Billion |
| **Total Profit** | ₹3.45 Billion |
| **Avg Margin** | ~19.97% |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Vanilla HTML5 / CSS3 / JavaScript (ES2020) |
| Charts | Chart.js 4.4.1 |
| Database | Supabase (PostgreSQL) with RLS |
| Auth | Session-based via `sessionStorage` |
| Fonts | Syne (headings) + DM Sans (body) — Google Fonts |
| Hosting | Any static host (Netlify, GitHub Pages, Vercel) |
| Offline | Browser `localStorage` fallback — works with zero server |

---

## 📁 File Reference

```
autopulse/
├── index.html        Login page — demo accounts on left, form on right
├── agency.html       Agency portal — sale entry + own records
├── dashboard.html    BI dashboard — full analytics, interactive charts
├── app.js            Shared core — Auth, DB, Refresh, Toast, fmt
├── seed_data.js      10,000 CSV rows as a JS array (3.4 MB)
├── schema.sql        Supabase DB schema, RLS, views
├── SETUP.md          Step-by-step Supabase + hosting guide
└── README.md         This file
```

---

## 🔒 Security Notes

- **Row Level Security** (RLS) is enabled on all Supabase tables
- Agency staff can only **INSERT** their own sales (enforced by `agency_id`)
- **No cross-agency read** — agencies see only rows matching their `agency_id`
- Dashboard roles get full **SELECT** on all sales
- ⚠️ Passwords are stored in plain text in the demo `users` table — in production, use **Supabase Auth** with email/password and remove the password column

---

## 📄 License

MIT License — free for personal and commercial use.

---

## 🙏 Acknowledgements

- Dataset inspired by India's automotive market structure (2024–2026)
- Charts powered by [Chart.js](https://chartjs.org)
- Database by [Supabase](https://supabase.com)
- Fonts by [Google Fonts](https://fonts.google.com)

---

*Built with ❤️ for India's automotive ecosystem*
