/**
 * Transform raw TopCV crawl data → JobHub DB schema (SQL seed).
 *
 * Reads:  data/jobs-raw.json     (from crawl.js)
 * Writes: data/seed.sql          (INSERT for employer + category + skill + job + job_skill)
 *         data/seed-summary.json (stats)
 *
 * Maps TopCV free-text → JobHub enums:
 *   salary   "12 - 16 triệu" → salary_min=12000000, salary_max=16000000, salary_period='MONTH'
 *                              "Thoả thuận"  → is_salary_negotiable=TRUE
 *   exp      "Không yêu cầu"  → experience_level='INTERN'
 *                              "Dưới 1 năm"  → 'FRESHER'
 *                              "1 năm".."4 năm" → 'JUNIOR'..'MID'
 *                              "5 năm"+      → 'SENIOR'
 *   location "Hà Nội & 5 nơi khác" → city='Hà Nội' (first city only)
 *
 * NOTE: This generates SQL with safe escaping. Run in Supabase SQL Editor.
 * Employers are de-duplicated by company_name. A default password_hash is
 * assigned so all seed employers share one login (FOR DEV ONLY).
 */
import { readFileSync, writeFileSync } from "node:fs";

const RAW_FILE = new URL("./data/jobs-raw.json", import.meta.url);
const OUT_SQL = new URL("./data/seed.sql", import.meta.url);
const OUT_SUMMARY = new URL("./data/seed-summary.json", import.meta.url);

// ---------- helpers ----------
const TRIEU = 1_000_000; // 1 triệu = 1,000,000 VND

/** Parse salary text like "15 - 50 triệu", "Từ 12 triệu", "Thoả thuận", "Trên 50 triệu" */
function parseSalary(text) {
  if (!text) return { isNegotiable: true };
  const t = text.toLowerCase().trim();
  if (t.includes("thoả thuận") || t.includes("thoa thuan"))
    return { isNegotiable: true };

  const m = t.match(/(\d[\d.]*)\s*-\s*(\d[\d.]*)\s*triệu/);
  if (m) {
    return {
      min: parseFloat(m[1]) * TRIEU,
      max: parseFloat(m[2]) * TRIEU,
      isNegotiable: false,
    };
  }
  const from = t.match(/từ\s+(\d[\d.]*)\s*triệu/);
  if (from) return { min: parseFloat(from[1]) * TRIEU, isNegotiable: false };
  const above = t.match(/trên\s+(\d[\d.]*)\s*triệu/);
  if (above) return { min: parseFloat(above[1]) * TRIEU, isNegotiable: false };
  const upto = t.match(
    /tối đa\s+(\d[\d.]*)\s*triệu|upto\s+(\d[\d.]*)\s*triệu|upto\s+(\d[\d.]*)/i,
  );
  if (upto) {
    const v = parseFloat(upto[1] || upto[2] || upto[3]);
    if (!isNaN(v)) return { max: v * TRIEU, isNegotiable: false };
  }
  return { isNegotiable: true };
}

/** Map experience text → JobHub experience_level enum */
function parseExperienceLevel(tags) {
  if (!tags || !tags.length) return null;
  const joined = tags.join(" ").toLowerCase();
  if (
    joined.includes("không yêu cầu") ||
    joined.includes("chưa có kinh nghiệm")
  )
    return "INTERN";
  if (joined.includes("dưới 1 năm")) return "FRESHER";
  // explicit year counts
  const m = joined.match(/(\d+)\s*năm/);
  if (m) {
    const y = parseInt(m[1], 10);
    if (y <= 1) return "JUNIOR";
    if (y <= 3) return "JUNIOR";
    if (y <= 4) return "MID";
    return "SENIOR";
  }
  if (joined.includes("trên 5 năm")) return "SENIOR";
  return null;
}

/** Map TopCV category name → existing JobHub category_id (assumes seeded categories).
 *  Returns the category name to look up; we use INSERT ... SELECT for id. */
function mapCategory(categoryName) {
  // JobHub has a category table with names; we store the TopCV name as-is
  // and resolve to category_id via subquery in SQL.
  return categoryName;
}

/** Take first city from "Hà Nội & 5 nơi khác" → "Hà Nội" */
function parseCity(locationText) {
  if (!locationText) return null;
  // strip "(mới)" suffix TopCV adds post-2025 merge
  let c = locationText
    .replace(/\s*\(mới\)\s*/g, "")
    .split("&")[0]
    .trim();
  // handle comma lists
  c = c.split(",")[0].trim();
  return c || null;
}

/** Map TopCV experience/role tags → work mode. Default ONSITE. */
function parseWorkMode(jobTitle, tags) {
  const t = (jobTitle + " " + (tags || []).join(" ")).toLowerCase();
  if (t.includes("remote")) return "REMOTE";
  if (t.includes("hybrid")) return "HYBRID";
  return "ONSITE";
}

/** Map to job_type. Most TopCV jobs are FULL_TIME unless stated. */
function parseJobType(text) {
  const t = (text || "").toLowerCase();
  if (t.includes("thực tập") || t.includes("intern")) return "INTERNSHIP";
  if (t.includes("part-time") || t.includes("bán thời gian"))
    return "PART_TIME";
  if (t.includes("thời vụ") || t.includes("contract")) return "CONTRACT";
  return "FULL_TIME";
}

/** Parse "Đăng 1 tuần trước" → approx days ago */
function parsePostedDays(text) {
  if (!text) return null;
  const t = text.toLowerCase();
  let m = t.match(/(\d+)\s*ngày/);
  if (m) return parseInt(m[1], 10);
  m = t.match(/(\d+)\s*tuần/);
  if (m) return parseInt(m[1], 10) * 7;
  return null;
}

/** SQL escape */
const sq = (s) => `'${String(s ?? "").replace(/'/g, "''")}'`;

// ---------- main ----------
function main() {
  const raw = JSON.parse(readFileSync(RAW_FILE, "utf8"));
  console.log(`Loaded ${raw.length} raw jobs`);

  // 1. De-duplicate employers by company_name
  const employerMap = new Map(); // company_name → { ...employer }
  let employerSeq = 1;
  for (const j of raw) {
    if (!j.company_name) continue;
    if (!employerMap.has(j.company_name)) {
      const slug = j.company_url
        ?.split("/")
        .find((s) => /^\d+\.html$/.test(s))
        ?.replace(".html", "");
      employerMap.set(j.company_name, {
        employer_key: `EMP${String(employerSeq++).padStart(4, "0")}`,
        company_name: j.company_name,
        company_url: j.company_url || null,
        company_logo: j.company_logo || null,
        email: `employer${employerSeq - 1}@seed.jobhub.local`,
        website: null,
        company_description: null,
        city: parseCity(j.location_text),
        is_verified: true,
        is_active: true,
        topcv_company_id: slug,
      });
    }
  }
  const employers = [...employerMap.values()];
  console.log(`→ ${employers.length} unique employers`);

  // 2. De-duplicate categories
  const categories = [
    ...new Set(raw.map((j) => j.category_name).filter(Boolean)),
  ];
  console.log(`→ ${categories.length} categories`);

  // 3. Build job rows
  const jobs = raw
    .filter((j) => j.job_title && j.company_name)
    .map((j, i) => {
      const salary = parseSalary(j.salary_text);
      const postedDays = parsePostedDays(j.posted_text);
      const createdAt = postedDays
        ? new Date(Date.now() - postedDays * 86400000).toISOString()
        : new Date().toISOString();
      const deadline = new Date(Date.now() + 30 * 86400000)
        .toISOString()
        .slice(0, 10);
      return {
        job_key: `JOB${String(i + 1).padStart(5, "0")}`,
        employer_company: j.company_name,
        category_name: mapCategory(j.category_name),
        job_title: j.job_title,
        job_description: j.job_detail ? JSON.stringify(j.job_detail) : null,
        // Prefer explicit hints from generator; fall back to parsing for crawled data.
        salary_min: j._salary_min ?? salary.min ?? null,
        salary_max: j._salary_max ?? salary.max ?? null,
        is_salary_negotiable: j._is_negotiable ?? salary.isNegotiable ?? false,
        salary_currency: "VND",
        salary_period: "MONTH",
        city: parseCity(j.location_text),
        location: j.location_text,
        work_mode:
          j._work_mode ?? parseWorkMode(j.job_title, j.experience_tags),
        job_type:
          j._job_type ??
          parseJobType(j.job_title + " " + (j.experience_tags || []).join(" ")),
        experience_level:
          j._experience_enum ?? parseExperienceLevel(j.experience_tags),
        positions_available: 1,
        application_deadline: deadline,
        status: "OPEN",
        is_approved: true,
        topcv_job_id: j.source_job_id,
        topcv_url: j.detail_url,
        created_at: createdAt,
      };
    });
  console.log(`→ ${jobs.length} job rows`);

  // 4. Extract skills from experience tags (heuristic: capitalized tokens)
  const skillSet = new Set();
  for (const j of raw) {
    for (const tag of j.experience_tags || []) {
      // treat each tag as potential skill if short enough
      const clean = tag.replace(/\+?\d*$/, "").trim();
      if (
        clean &&
        clean.length > 2 &&
        clean.length < 60 &&
        !/kinh nghiệm/i.test(clean)
      ) {
        skillSet.add(clean);
      }
    }
  }
  const skills = [...skillSet].slice(0, 200); // cap
  console.log(`→ ${skills.length} candidate skills`);

  // ---------- write SQL ----------
  const sql = [];
  sql.push("-- ============================================================");
  sql.push("-- JobHub seed data — generated from TopCV crawl");
  sql.push(`-- Generated: ${new Date().toISOString()}`);
  sql.push(
    `-- Source jobs: ${raw.length}, employers: ${employers.length}, categories: ${categories.length}`,
  );
  sql.push("-- ⚠️  Run in Supabase SQL Editor. Uses CTE for key resolution.");
  sql.push("-- ============================================================\n");

  // Default password hash for seed employers (bcrypt of 'seed12345')
  const SEED_PW_HASH =
    "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"; // 'seed12345'

  // Employers
  sql.push("-- EMPLOYERS (de-duplicated by company_name)");
  sql.push("-- Shared password for all seed employers: seed12345");
  for (const e of employers) {
    sql.push(
      `INSERT INTO employer (company_name, email, password_hash, website, company_description, city, is_verified, is_active)`,
    );
    sql.push(
      `VALUES (${sq(e.company_name)}, ${sq(e.email)}, '${SEED_PW_HASH}', NULL, NULL, ${sq(e.city)}, TRUE, TRUE)`,
    );
    sql.push(`ON CONFLICT (email) DO NOTHING;`);
  }
  sql.push("");

  // Categories (upsert)
  sql.push("-- CATEGORIES");
  for (const c of categories) {
    sql.push(
      `INSERT INTO category (name) VALUES (${sq(c)}) ON CONFLICT (name) DO NOTHING;`,
    );
  }
  sql.push("");

  // Skills (upsert)
  sql.push("-- SKILLS (heuristic, from job tags)");
  for (const s of skills) {
    sql.push(
      `INSERT INTO skill (skill_name) VALUES (${sq(s)}) ON CONFLICT (skill_name) DO NOTHING;`,
    );
  }
  sql.push("");

  // Jobs — emit chunked INSERTs, each resolving employer_id + category_id by name via CTE
  sql.push(
    "-- JOBS (resolves employer_id + category_id by name via CTE subquery)",
  );
  const CHUNK = 100;
  for (let i = 0; i < jobs.length; i += CHUNK) {
    const chunk = jobs.slice(i, i + CHUNK);
    const values = chunk
      .map(
        (j) =>
          `    (${sq(j.job_title)}, ${j.job_description ? sq(j.job_description) : "NULL"}, ${j.salary_min ?? "NULL"}, ${j.salary_max ?? "NULL"}, ${j.is_salary_negotiable ? "TRUE" : "FALSE"}, ${sq(j.salary_currency)}, ${sq(j.salary_period)}, ${sq(j.city)}, ${sq(j.location)}, ${sq(j.work_mode)}, ${sq(j.job_type)}, ${j.experience_level ? sq(j.experience_level) : "NULL"}, ${j.positions_available}, ${sq(j.application_deadline)}, ${sq(j.status)}, ${j.is_approved ? "TRUE" : "FALSE"}, ${sq(j.created_at)}::timestamptz, ${sq(j.employer_company)}, ${sq(j.category_name)})`,
      )
      .join(",\n");
    sql.push(`WITH job_chunk_${i} AS (
  SELECT * FROM (VALUES
${values}
  ) AS t(job_title, job_description, salary_min, salary_max, is_salary_negotiable, salary_currency, salary_period, city, location, work_mode, job_type, experience_level, positions_available, application_deadline, status, is_approved, created_at, employer_company, category_name)
)
INSERT INTO job (
  employer_id, category_id, job_title, job_description, salary_min, salary_max,
  is_salary_negotiable, salary_currency, salary_period, city, location,
  work_mode, job_type, experience_level, positions_available,
  application_deadline, status, is_approved, created_at
)
SELECT
  e.employer_id,
  c.category_id,
  t.job_title, t.job_description, t.salary_min, t.salary_max,
  t.is_salary_negotiable, t.salary_currency, t.salary_period, t.city, t.location,
  t.work_mode::work_mode, t.job_type::job_type, t.experience_level::experience_level,
  t.positions_available, t.application_deadline, t.status::job_status, t.is_approved, t.created_at
FROM job_chunk_${i} t
JOIN employer e ON e.company_name = t.employer_company
LEFT JOIN category c ON c.name = t.category_name
ON CONFLICT DO NOTHING;`);
    sql.push("");
  }

  writeFileSync(OUT_SQL, sql.join("\n"));
  console.log(`\n✓ wrote ${OUT_SQL.pathname.replace(/^\/([A-Z]:)/, "$1")}`);

  // summary
  const summary = {
    generated_at: new Date().toISOString(),
    source_jobs: raw.length,
    unique_employers: employers.length,
    categories: categories.length,
    candidate_skills: skills.length,
    jobs_to_insert: jobs.length,
    salary_filled: jobs.filter((j) => !j.is_salary_negotiable).length,
    negotiable: jobs.filter((j) => j.is_salary_negotiable).length,
    work_mode_breakdown: tally(jobs.map((j) => j.work_mode)),
    job_type_breakdown: tally(jobs.map((j) => j.job_type)),
    experience_breakdown: tally(jobs.map((j) => j.experience_level || "NULL")),
    top_cities: topN(tally(jobs.map((j) => j.city || "Unknown")), 10),
  };
  writeFileSync(OUT_SUMMARY, JSON.stringify(summary, null, 2));
  console.log(`✓ wrote summary`);
  console.log("\nSummary:", JSON.stringify(summary, null, 2));
}

function tally(arr) {
  const m = {};
  for (const x of arr) m[x] = (m[x] || 0) + 1;
  return m;
}
function topN(obj, n) {
  return Object.entries(obj)
    .sort((a, b) => b[1] - a[1])
    .slice(0, n);
}

main();
