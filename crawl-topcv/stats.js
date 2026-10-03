/**
 * Thống kê dataset synthetic data/jobs-raw.json → data/stats.json (dùng cho
 * docs/10_CRAWL_DATASET.md). Chạy: node stats.js [--file=<path>]
 *
 * Không dùng dependency ngoài (node:fs + node:crypto).
 */
import { readFileSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const m = a.match(/^--([^=]+)=(.*)$/);
    return m ? [m[1], m[2]] : [a.slice(2), "1"];
  }),
);

const FILE = args.file
  ? args.file
  : fileURLToPath(new URL("./data/jobs-raw.json", import.meta.url));
const OUT = fileURLToPath(new URL("./data/stats.json", import.meta.url));

const RAW = JSON.parse(readFileSync(FILE, "utf8"));
const buf = readFileSync(FILE);
const sha256 = createHash("sha256").update(buf).digest("hex");

// ── helpers ──────────────────────────────────────────────────────────────
const strip = (s) =>
  s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/đ/g, "d")
    .replace(/\s+/g, " ")
    .trim();

function histogram(key, transform = (v) => v) {
  const m = new Map();
  for (const j of RAW) {
    const v = transform(j[key] ?? "");
    m.set(v, (m.get(v) || 0) + 1);
  }
  return [...m.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
}

function quantile(sorted, q) {
  if (sorted.length === 0) return null;
  const pos = (sorted.length - 1) * q;
  const lo = Math.floor(pos);
  const hi = Math.ceil(pos);
  if (lo === hi) return sorted[lo];
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

function stats(nums) {
  const s = [...nums].sort((a, b) => a - b);
  if (s.length === 0) return null;
  const sum = s.reduce((a, b) => a + b, 0);
  return {
    n: s.length,
    min: s[0],
    p10: quantile(s, 0.1),
    p25: quantile(s, 0.25),
    median: quantile(s, 0.5),
    p75: quantile(s, 0.75),
    p90: quantile(s, 0.9),
    max: s[s.length - 1],
    mean: sum / s.length,
  };
}

// ── unique employers ─────────────────────────────────────────────────────
const byName = new Map(); // name lower+stripped → count
const bySlug = new Map(); // uid kiểu import-firestore.js → count
for (const j of RAW) {
  const k = strip(j.company_name);
  byName.set(k, (byName.get(k) || 0) + 1);
  const slug = k
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 40);
  bySlug.set(`crawl-${slug}`, (bySlug.get(`crawl-${slug}`) || 0) + 1);
}

// ── salary ───────────────────────────────────────────────────────────────
const mins = RAW.filter((j) => j._salary_min != null).map((j) => j._salary_min);
const maxs = RAW.filter((j) => j._salary_max != null).map((j) => j._salary_max);
const negotiable = RAW.filter((j) => j._is_negotiable === true).length;

// ── base city (bỏ phần "& N nơi khác") ───────────────────────────────────
const baseCity = histogram("location_text", (v) => v.split("&")[0].trim());

// ── sample jobs ─────────────────────────────────────────────────────────
function sample(i) {
  const j = RAW[i];
  if (!j) return null;
  const trimList = (l) =>
    Array.isArray(l)
      ? l.length <= 3
        ? l
        : [...l.slice(0, 3), `… (còn ${l.length - 3} mục)`]
      : l;
  return {
    index: i,
    source_job_id: j.source_job_id,
    job_title: j.job_title,
    company_name: j.company_name,
    category_name: j.category_name,
    salary_text: j.salary_text,
    location_text: j.location_text,
    _salary_min: j._salary_min,
    _salary_max: j._salary_max,
    _is_negotiable: j._is_negotiable,
    _experience_enum: j._experience_enum,
    _work_mode: j._work_mode,
    _job_type: j._job_type,
    posted_text: j.posted_text,
    crawled_at: j.crawled_at,
    job_detail: j.job_detail
      ? {
          mo_ta_cong_viec: trimList(j.job_detail.mo_ta_cong_viec),
          yeu_cau_ung_vien: trimList(j.job_detail.yeu_cau_ung_vien),
          quyen_loi: trimList(j.job_detail.quyen_loi),
          thoi_gian_lam_viec: j.job_detail.thoi_gian_lam_viec,
          yeu_cau_kinh_nghiem: j.job_detail.yeu_cau_kinh_nghiem,
          yeu_cau_bang_cap: j.job_detail.yeu_cau_bang_cap,
        }
      : null,
  };
}

const out = {
  file: FILE,
  bytes: buf.length,
  sha256,
  totalJobs: RAW.length,
  uniqueCompaniesByName: byName.size,
  uniqueEmployerUidsBySlug: bySlug.size,
  slugCollisions: byName.size - bySlug.size,
  categories: histogram("category_name"),
  locations: histogram("location_text"),
  baseCities: baseCity,
  experience: histogram("_experience_enum"),
  workMode: histogram("_work_mode"),
  jobType: histogram("_job_type"),
  salaryMin: stats(mins),
  salaryMax: stats(maxs),
  negotiableCount: negotiable,
  negotiablePct: ((negotiable / RAW.length) * 100).toFixed(2),
  samples: [sample(0), sample(4899), sample(9799)],
};

writeFileSync(OUT, JSON.stringify(out, null, 2));
console.log(`OK → ${OUT}`);
console.log(JSON.stringify({
  totalJobs: out.totalJobs,
  uniqueCompaniesByName: out.uniqueCompaniesByName,
  uniqueEmployerUidsBySlug: out.uniqueEmployerUidsBySlug,
  slugCollisions: out.slugCollisions,
  sha256: out.sha256,
  negotiable: out.negotiableCount,
}, null, 2));
