/* ================================================================
   AutoPulse — Production Core  (app.js)
   ─────────────────────────────────────────────────────────────────
   SUPABASE SETUP:
     1. https://app.supabase.com → Project → Settings → API
     2. Replace SUPABASE_URL and SUPABASE_ANON_KEY below
     3. Run schema.sql in Supabase → SQL Editor
   Without valid config the app runs on browser localStorage.
   ================================================================ */

const SUPABASE_URL = 'postgresql://postgres.jxhczcydbasgdiukmfcw:$Suraj@123$@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4aGN6Y3lkYmFzZ2RpdWttZmN3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1MzUxMjksImV4cCI6MjA5MDExMTEyOX0.jYeph4QWtzK7iV-hc6D5whPOHSZvaG_9I2kWiVMAghk';

const DB_ENABLED = SUPABASE_URL !== 'true';
const _sb = DB_ENABLED ? supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;

/* ── USER DIRECTORY (fallback when Supabase not configured) ─── */
const USERS = {
  admin: { password: 'Admin@2024', role: 'admin', name: 'National Admin', agency: null, state: null, city: null },
  manager: { password: 'Mgr@2024', role: 'manager', name: 'Regional Manager', agency: null, state: null, city: null },
  official: { password: 'Gov@2024', role: 'govt', name: 'Govt. Official', agency: null, state: null, city: null },
  mum_hub: { password: 'Mum@2024', role: 'agency', name: 'Mumbai AutoHub', agency: 'mum_hub', state: 'Maharashtra', city: 'Mumbai' },
  pune_motors: { password: 'Pune@2024', role: 'agency', name: 'Pune Motors', agency: 'pune_motors', state: 'Maharashtra', city: 'Pune' },
  del_elite: { password: 'Del@2024', role: 'agency', name: 'Delhi Elite Cars', agency: 'del_elite', state: 'Delhi', city: 'New Delhi' },
  blr_drive: { password: 'Blr@2024', role: 'agency', name: 'Bangalore DriveZone', agency: 'blr_drive', state: 'Karnataka', city: 'Bangalore' },
  bpl_auto: { password: 'Bpl@2024', role: 'agency', name: 'Bhopal AutoWorld', agency: 'bpl_auto', state: 'Madhya Pradesh', city: 'Bhopal' },
};

/* ── AUTH ──────────────────────────────────────────────────────── */
const Auth = {
  async login(user, pass) {
    if (_sb) {
      try {
        const { data } = await _sb.from('users').select('*')
          .eq('username', user).eq('password', pass).single();
        if (data) { Auth._save(data); return { ok: true, user: data }; }
      } catch (_) { }
    }
    const u = USERS[user];
    if (u && u.password === pass) {
      const obj = { username: user, ...u };
      Auth._save(obj);
      return { ok: true, user: obj };
    }
    return { ok: false };
  },
  _save(u) { sessionStorage.setItem('ap_user', JSON.stringify(u)); },
  get() { try { return JSON.parse(sessionStorage.getItem('ap_user')); } catch (_) { return null; } },
  logout() { sessionStorage.removeItem('ap_user'); location.href = 'index.html'; },
  require(roles) {
    const u = Auth.get();
    if (!u || !roles.includes(u.role)) { location.href = 'index.html'; return null; }
    return u;
  },
};

/* ── DATABASE ──────────────────────────────────────────────────── */
const DB = {
  async insertSale(rec) {
    if (_sb) {
      const { error } = await _sb.from('sales').insert([rec]);
      if (!error) return { ok: true, src: 'supabase' };
    }
    const k = 'ap_sales_' + rec.agency_id;
    const a = JSON.parse(localStorage.getItem(k) || '[]');
    a.unshift(rec);
    localStorage.setItem(k, JSON.stringify(a));
    return { ok: true, src: 'local' };
  },
  async getAgencySales(aid) {
    if (_sb) {
      try {
        const { data } = await _sb.from('sales').select('*')
          .eq('agency_id', aid).order('submitted_at', { ascending: false });
        if (data) return { rows: data, src: 'supabase' };
      } catch (_) { }
    }
    return { rows: JSON.parse(localStorage.getItem('ap_sales_' + aid) || '[]'), src: 'local' };
  },
  async getAllSales() {
    if (_sb) {
      try {
        const { data } = await _sb.from('sales').select('*')
          .order('submitted_at', { ascending: false });
        if (data) return { rows: data, src: 'supabase' };
      } catch (_) { }
    }
    let all = [];
    Object.values(USERS).filter(u => u.role === 'agency' && u.agency).forEach(u => {
      all = all.concat(JSON.parse(localStorage.getItem('ap_sales_' + u.agency) || '[]'));
    });
    return { rows: all.sort((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at)), src: 'local' };
  },
};

/* ── INVOICE COUNTER ───────────────────────────────────────────── */
const InvCounter = {
  next(aid) {
    const k = 'ap_inv_' + aid;
    const n = parseInt(localStorage.getItem(k) || '11000') + 1;
    localStorage.setItem(k, n);
    return 'INV' + n;
  },
};

/* ── AUTO-REFRESH (24-hour cycle) ──────────────────────────────── */
const Refresh = {
  MS: 24 * 60 * 60 * 1000,
  _tid: null, _next: 0,
  start(cb) {
    const s = parseInt(localStorage.getItem('ap_next_refresh') || '0');
    this._next = s > Date.now() ? s : Date.now() + this.MS;
    localStorage.setItem('ap_next_refresh', this._next);
    this._tick();
    this._tid = setInterval(async () => {
      if (Date.now() >= this._next) {
        this._next = Date.now() + this.MS;
        localStorage.setItem('ap_next_refresh', this._next);
        await cb();
      }
      this._tick();
    }, 1000);
  },
  _tick() {
    const l = Math.max(0, this._next - Date.now());
    const t = [l / 3600000, (l % 3600000) / 60000, (l % 60000) / 1000]
      .map(v => String(Math.floor(v)).padStart(2, '0')).join(':');
    document.querySelectorAll('[data-countdown]').forEach(el => el.textContent = t);
  },
  stop() { clearInterval(this._tid); },
};

/* ── FORMATTING ────────────────────────────────────────────────── */
const fmt = {
  inr: n => '₹' + Math.round(n).toLocaleString('en-IN'),
  inrB: n => '₹' + (n / 1e9).toFixed(3) + 'B',
  inrM: n => '₹' + (n / 1e6).toFixed(2) + 'M',
  inrCr: n => '₹' + (n / 1e7).toFixed(2) + 'Cr',
  pct: n => (+n).toFixed(2) + '%',
  date: d => { try { return new Date(d).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }); } catch (_) { return d; } },
  now: () => new Date().toLocaleString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
};

/* ── TOAST ─────────────────────────────────────────────────────── */
const Toast = {
  show(type, title, msg, ms = 3800) {
    let el = document.getElementById('ap-toast');
    if (!el) {
      el = document.createElement('div');
      el.id = 'ap-toast';
      el.style.cssText = 'position:fixed;bottom:24px;right:24px;z-index:9999;transform:translateX(130%);transition:transform .45s cubic-bezier(0.34,1.56,0.64,1);font-family:Satoshi,sans-serif;';
      document.body.appendChild(el);
    }
    const C = { ok: '#3dd68c', err: '#ff5c5c', warn: '#f5c842', info: '#4a9eff' };
    const I = { ok: '✅', err: '❌', warn: '⚠️', info: 'ℹ️' };
    const bg = getComputedStyle(document.documentElement).getPropertyValue('--surface').trim() || '#fff';
    const bd = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#ddd';
    el.innerHTML = `<div style="background:${bg};border:1px solid ${bd};border-left:3px solid ${C[type] || C.info};border-radius:12px;padding:14px 20px;display:flex;align-items:flex-start;gap:12px;box-shadow:0 8px 32px rgba(0,0,0,.18);min-width:270px;max-width:380px"><span style="font-size:20px;flex-shrink:0;margin-top:1px">${I[type] || I.info}</span><div><div style="font-weight:700;font-size:13px;color:${C[type] || C.info}">${title}</div><div style="font-size:12px;color:var(--muted,#888);margin-top:3px;line-height:1.5">${msg}</div></div></div>`;
    el.style.transform = 'translateX(0)';
    clearTimeout(Toast._t);
    Toast._t = setTimeout(() => el.style.transform = 'translateX(130%)', ms);
  },
};
