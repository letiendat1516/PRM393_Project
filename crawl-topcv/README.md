# TopCV → JobHub Data Seeder

Generates realistic job seed data for the JobHub database using **real TopCV
reference data** (categories, cities, salary ranges, experience levels,
filter values) combined with a **synthetic job generator**.

## Why this approach?

TopCV is behind Cloudflare, which rate-limits automated access to ~1-2 page
loads per IP before blocking. Crawling thousands of jobs directly is not
reliable. Instead we:

1. **Extract real reference data** from TopCV (categories, filter options,
   salary ranges, cities) — these are stable and come from a single page
   inspection.
2. **Synthesize realistic jobs** from these real building blocks — job
   titles per category, realistic company names, real salary/city/experience
   distributions.

This gives 5000+ realistic Vietnamese jobs in seconds, reproducibly, with no
Cloudflare dependence.

## Quick start

### Option A — Crawl real jobs (headed mode, manual CF solving)

TopCV sits behind Cloudflare. The crawler runs **HEADED by default** (browser
window visible) so you can solve any Cloudflare/Turnstile challenge **by hand**
when it appears. Crawling auto-resumes once the challenge clears.

```bash
cd scripts/crawl-topcv
npm install
npx playwright install chromium

# 1. Crawl (browser opens — solve CF challenge if it pops up)
#    Default: ~50 categories × 10 pages = ~25000 jobs. Long-running; resumable.
node crawl.js
#    Or limit:   node crawl.js --cats=10 --pages=5
#    Or headless (no manual CF solving, will be blocked after ~2 pages):
#    node crawl.js --headless=1

# 2. Export crawled jobs → frontend JSON
node export-frontend.js --limit=500
#    → writes ../../frontend/src/data/jobsCrawled.json
#    → JobsPage automatically uses it instead of the 12-job mock

# 3. (Optional) Transform → SQL seed for Supabase
node transform.js
```

### Option B — Generate synthetic jobs (no crawler, instant)

```bash
cd scripts/crawl-topcv
node generate.js          # 500 jobs/category × 49 categories = 24500
node transform.js        # → data/seed.sql
```

## How it works

```
reference.js  (real TopCV data: 49 categories, 63 cities, salary ranges,
               experience levels, job types, company name components,
               per-category title pools)
       │
       ▼
   generate.js   →  data/jobs-raw.json  (5000 jobs, deterministic)
       │
       ▼
   transform.js  →  data/seed.sql       (INSERT employer + category + job)
       │
       ▼
   Supabase
```

### Realism guarantees

The generator uses **only real values** from TopCV as building blocks:

| Field | Source |
|-------|--------|
| Job titles | Real TopCV titles per category (e.g. "Backend Developer", "Kế Toán Tổng Hợp") |
| Categories | 49 real TopCV category slugs + names |
| Cities | 63 real Vietnamese provinces, weighted by real job volume (HCM 32%, HN 28%, ...) |
| Salary ranges | Real TopCV filter ranges ("10 - 15 triệu" → 10,000,000-15,000,000 VND) |
| Experience levels | Real TopCV values mapped to JobHub enums |
| Company names | Real Vietnamese company-name patterns (CÔNG TY TNHH/CỔ PHẦN + real brand components) |
| Work mode distribution | 80% onsite, 12% hybrid, 8% remote (matches real market) |
| Posted dates | "Đăng X ngày/tuần trước" format |

### Determinism

The generator uses a **seeded RNG** (mulberry32, seed 20260708), so re-running
`generate.js` produces identical output. Change the seed in `generate.js`
(line ~38: `let _seed = ...`) for a different dataset.

## Files

| File | Purpose |
|------|---------|
| `reference.js` | **Real reference data** from TopCV (categories, filters, cities, title pools). Edit to add/remove categories or titles. |
| `generate.js` | **Synthetic generator** — combines reference data into 5000 jobs. Deterministic. |
| `transform.js` | Maps raw jobs → JobHub DB schema (enums, FK resolution via CTE). |
| `crawl.js` | Direct Playwright crawler (kept for reference; Cloudflare-blocked in practice). |
| `extract-categories.js` | One-off script to re-extract category slugs from TopCV. |
| `probe*.js` | DOM inspection scripts (dev only). |
| `data/` | Output (gitignored): `jobs-raw.json`, `seed.sql`, `seed-summary.json`. |

## Configuration

### Change jobs per category

```bash
node generate.js --perCategory=1000   # 1000/category × 49 = 49000 jobs
```

### Add a category

Edit `reference.js` → add to `CATEGORIES`, add title pool to
`TITLE_FAMILIES`, add mapping to `CATEGORY_FAMILY`.

### Merge real + synthetic data

If you later collect a batch of real jobs (e.g. 100 from a successful
1-page crawl), place them in `data/jobs-real.json` and merge before
transforming:

```js
// in transform.js, change the load line:
const real = JSON.parse(readFileSync(RAW_FILE_REAL, 'utf8'));
const synth = JSON.parse(readFileSync(RAW_FILE, 'utf8'));
const raw = [...real, ...synth];
```

## Field mapping (reference → JobHub schema)

| Reference | JobHub column | Notes |
|-----------|---------------|-------|
| job title | `job.job_title` | from per-category title pool |
| company name | `employer.company_name` | de-duplicated; ~1523 unique for 5000 jobs |
| salary range | `job.salary_min`, `salary_max` | "10 - 15 triệu" → 10M-15M VND; "Thoả thuận" → negotiable |
| city | `job.city` | first city from location text |
| experience | `job.experience_level` | INTERN/FRESHER/JUNIOR/MID/SENIOR/LEAD enum |
| work mode | `job.work_mode` | ONSITE/HYBRID/REMOTE enum |
| job type | `job.job_type` | FULL_TIME/PART_TIME/INTERNSHIP enum |
| posted text | `job.created_at` | back-calculated from today |
| category | `job.category_id` | resolved via JOIN on `category.name` |

## Seed employer login

All seed employers share password `seed12345` (bcrypt hash in `transform.js`).
For development only.

## Notes

- **Reproducible**: same seed → same data. Safe to re-run.
- **Schema-compliant**: output matches `docs/08_DATABASE.md` exactly (enums,
  FKs, types). Uses `ON CONFLICT DO NOTHING` for idempotent re-imports.
- **`job_description`**: stored as **structured JSON** with 4 sections, matching the
  TopCV "View Job Details" page layout:
  ```json
  {
    "mo_ta_cong_viec": ["bullet1", "bullet2", ...],   // responsibilities
    "yeu_cau_ung_vien": ["req1", "req2", ...],         // candidate requirements
    "quyen_loi":         ["benefit1", ...],            // benefits
    "thoi_gian_lam_viec": "Thứ 2 - Thứ 6 (từ 09:00 đến 18:00)",
    "yeu_cau_kinh_nghiem": "3 năm",
    "yeu_cau_bang_cap":   "Đại học trở lên"
  }
  ```
  The frontend (UC06 View Job Details) should `JSON.parse(job_description)`
  and render each section. IT jobs use English content (like real TopCV IT
  posts); all other industries use Vietnamese. Each job mixes a random subset
  of family-specific bullets so no two jobs are identical. Update
  `reference-descriptions.js` to add/modify content per industry.
