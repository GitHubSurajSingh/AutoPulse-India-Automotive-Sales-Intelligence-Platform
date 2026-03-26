# AutoPulse — Setup Guide

## Files in this package

```
autopulse/
├── index.html      ← Login page (all users start here)
├── agency.html     ← Agency portal (sale entry + own records)
├── dashboard.html  ← BI analytics (managers, govt, admin)
├── app.js          ← Shared auth, DB helpers, config
├── schema.sql      ← Supabase database schema + seed users
└── SETUP.md        ← This file
```

---

## Step 1 — Open locally (works immediately, no setup needed)

1. Put all files in one folder
2. Open `index.html` in a browser
3. Use any demo account from the login page
4. Data is stored in **browser localStorage** — works offline

---

## Step 2 — Connect Supabase (optional, for real shared database)

### Create a free Supabase project
1. Go to **https://app.supabase.com** and sign up free
2. Click **New Project** → name it `autopulse` → choose Singapore region
3. Set a database password → **Create Project**

### Run the SQL schema
1. In your Supabase dashboard → **SQL Editor**
2. Paste the entire contents of `schema.sql`
3. Click **Run** — this creates users, sales tables, RLS policies, and views

### Get your API credentials
1. Supabase dashboard → **Project Settings** → **API**
2. Copy:
   - **Project URL** → looks like `https://xyzabc.supabase.co`
   - **anon public** key → starts with `eyJ...`

### Configure the app
Open `app.js` and edit the top two lines:
```js
const SUPABASE_URL      = 'https://YOUR-PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'eyJ...your-anon-key...';
```

---

## Step 3 — Deploy (free hosting)

**Option A: Netlify Drop (30 seconds)**
1. Go to https://app.netlify.com/drop
2. Drag your `autopulse/` folder onto the page
3. Done — live HTTPS URL instantly

**Option B: GitHub Pages**
1. Push folder contents to a GitHub repository
2. Settings → Pages → Deploy from main branch → root folder

**Option C: Run locally**
```bash
cd autopulse
npx serve .
# Open http://localhost:3000
```

---

## User Accounts & Role Matrix

| Username       | Password    | Role    | Can See                            |
|---------------|-------------|---------|-------------------------------------|
| `admin`       | Admin@2024  | Admin   | Full BI dashboard + admin panel     |
| `manager`     | Mgr@2024    | Manager | Full BI analytics — all data        |
| `official`    | Gov@2024    | Govt    | Read-only BI analytics — all data  |
| `mum_hub`     | Mum@2024    | Agency  | Enter sales + own records only      |
| `pune_motors` | Pune@2024   | Agency  | Enter sales + own records only      |
| `del_elite`   | Del@2024    | Agency  | Enter sales + own records only      |
| `blr_drive`   | Blr@2024    | Agency  | Enter sales + own records only      |
| `bpl_auto`    | Bpl@2024    | Agency  | Enter sales + own records only      |

---

## How data flows

```
Agency staff logs in
       ↓
Fills sale form → prices auto-calculated (RTO 10.5%, insurance 3.2%, cost 87%)
       ↓
Record saved → Supabase `sales` table  (or localStorage if no DB configured)
       ↓
Manager / Govt logs in
       ↓
dashboard.html loads:
  • Seed dataset (10,000 pre-cleaned records, aggregated in JS)
  • + Live agency submissions from `sales` table
  • Auto-refreshes every 24 hours
  • Manual refresh button also available
```

---

## Auto-refresh behaviour

- Dashboard shows a countdown timer to next refresh (top bar)
- At 24-hour mark, `DB.getAllSales()` is called automatically
- New agency submissions are merged with seed analytics
- Manual **Refresh Now** button triggers the same flow instantly
- Refresh state is persisted in `localStorage` (survives page reloads)
