/**
 * Export crawled jobs → frontend mock JSON.
 *
 * Reads:  data/jobs-raw.json   (real jobs from crawl.js)
 * Writes: ../../frontend/src/data/jobsCrawled.json  (normalized for frontend)
 *
 * After running this, update frontend/src/data/jobsList.js to import from
 * jobsCrawled.json instead of the hardcoded 12-job array. (Or wire directly.)
 *
 * Run:  node export-frontend.js [--limit=500]
 */
import { readFileSync, writeFileSync } from "node:fs";

const RAW_FILE = new URL("./data/jobs-raw.json", import.meta.url);
const OUT_FILE = new URL(
  "../../frontend/src/data/jobsCrawled.json",
  import.meta.url,
);

// ---- CLI ----
const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const m = a.match(/^--([^=]+)=(.*)$/);
    return m ? [m[1], m[2]] : [a.slice(2), "1"];
  }),
);
const LIMIT = args.limit ? parseInt(args.limit, 10) : 10000;

// ---- normalize helpers (mirror frontend/src/data/jobsList.js) ----
const EXP_LABEL = {
  INTERN: "Không yêu cầu",
  FRESHER: "Dưới 1 năm",
  JUNIOR: "1 - 2 năm",
  MID: "2 - 4 năm",
  SENIOR: "5 năm",
  LEAD: "Trên 5 năm",
};
const JOB_TYPE_LABEL = {
  FULL_TIME: "Toàn thời gian",
  PART_TIME: "Bán thời gian",
  INTERNSHIP: "Thực tập",
};
const WORK_MODE_LABEL = {
  ONSITE: "Tại văn phòng",
  REMOTE: "Remote",
  HYBRID: "Hybrid",
};

function companyBrand(name) {
  const clean = (name || "").replace(/^CÔNG TY\s+\w+\s+/, "").trim();
  const initials = (
    clean.match(/[A-ZÀ-Ỹ]{2,}/g)?.[0] ??
    clean.slice(0, 2) ??
    "CO"
  )
    .slice(0, 3)
    .toUpperCase();
  const palettes = [
    "bg-orange-50 text-orange-600",
    "bg-pink-50 text-pink-600",
    "bg-amber-50 text-amber-600",
    "bg-red-50 text-red-600",
    "bg-sky-50 text-sky-600",
    "bg-green-50 text-green-600",
    "bg-violet-50 text-violet-600",
    "bg-teal-50 text-teal-600",
    "bg-indigo-50 text-indigo-600",
    "bg-rose-50 text-rose-600",
  ];
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return { name, initials, brand: palettes[h % palettes.length] };
}

/** Parse salary text like "15 - 25 triệu", "Từ 12 triệu", "Thoả thuận" */
function parseSalary(text) {
  if (!text) return { min: null, max: null, negotiable: true };
  const t = text.toLowerCase();
  if (t.includes("thoả thuận") || t.includes("thoa thuan"))
    return { min: null, max: null, negotiable: true };
  const m = t.match(/(\d[\d.]*)\s*-\s*(\d[\d.]*)\s*triệu/);
  if (m)
    return {
      min: parseFloat(m[1]) * 1_000_000,
      max: parseFloat(m[2]) * 1_000_000,
      negotiable: false,
    };
  const from = t.match(/từ\s+(\d[\d.]*)\s*triệu/);
  if (from)
    return {
      min: parseFloat(from[1]) * 1_000_000,
      max: null,
      negotiable: false,
    };
  const upto = t.match(/upto\s+(\d[\d.]*)\s*triệu/i);
  if (upto)
    return {
      min: null,
      max: parseFloat(upto[1]) * 1_000_000,
      negotiable: false,
    };
  return { min: null, max: null, negotiable: true };
}

/** Parse experience text → enum */
function parseExperience(expTags) {
  if (!expTags || !expTags.length)
    return { enum: null, label: "Không yêu cầu" };
  const joined = expTags.join(" ").toLowerCase();
  if (joined.includes("không yêu cầu") || joined.includes("chưa có"))
    return { enum: "INTERN", label: "Không yêu cầu" };
  if (joined.includes("dưới 1 năm"))
    return { enum: "FRESHER", label: "Dưới 1 năm" };
  const m = joined.match(/(\d+)\s*năm/);
  if (m) {
    const y = parseInt(m[1], 10);
    if (y <= 2) return { enum: "JUNIOR", label: "1 - 2 năm" };
    if (y <= 4) return { enum: "MID", label: "2 - 4 năm" };
    if (y <= 5) return { enum: "SENIOR", label: "5 năm" };
    return { enum: "LEAD", label: "Trên 5 năm" };
  }
  return { enum: null, label: "Không yêu cầu" };
}

function normalizeJob(raw) {
  // Parse salary from text if _hints not available (real crawled data).
  const salaryParsed = parseSalary(raw.salary_text);
  const expParsed = parseExperience(raw.experience_tags);
  // Detect work mode from title/tags
  let workMode = raw._work_mode ?? null;
  if (!workMode) {
    const hay =
      `${raw.job_title ?? ""} ${(raw.experience_tags || []).join(" ")}`.toLowerCase();
    if (hay.includes("remote")) workMode = "REMOTE";
    else if (hay.includes("hybrid")) workMode = "HYBRID";
    else workMode = "ONSITE";
  }
  let jobType = raw._job_type ?? null;
  if (!jobType) {
    const hay = `${raw.job_title ?? ""}`.toLowerCase();
    if (hay.includes("thực tập") || hay.includes("intern"))
      jobType = "INTERNSHIP";
    else if (hay.includes("part-time") || hay.includes("bán thời gian"))
      jobType = "PART_TIME";
    else jobType = "FULL_TIME";
  }
  return {
    id: raw.source_job_id,
    title: raw.job_title,
    company: companyBrand(raw.company_name),
    companyLogo: raw.company_logo || null,
    companyUrl: raw.company_url || null,
    category: raw.category_name,
    salaryLabel: raw.salary_text || "Thoả thuận",
    salaryMin: raw._salary_min ?? salaryParsed.min,
    salaryMax: raw._salary_max ?? salaryParsed.max,
    negotiable: raw._is_negotiable ?? salaryParsed.negotiable,
    location:
      raw.location_text
        ?.split("&")[0]
        .replace(/\s*\(mới\)\s*/g, "")
        .trim() ?? "",
    experienceLabel: EXP_LABEL[raw._experience_enum] ?? expParsed.label,
    experienceEnum: raw._experience_enum ?? expParsed.enum,
    employmentType:
      JOB_TYPE_LABEL[raw._job_type] ??
      JOB_TYPE_LABEL[jobType] ??
      "Toàn thời gian",
    jobTypeEnum: raw._job_type ?? jobType,
    workType:
      WORK_MODE_LABEL[raw._work_mode] ??
      WORK_MODE_LABEL[workMode] ??
      "Tại văn phòng",
    workModeEnum: raw._work_mode ?? workMode,
    tags: raw.experience_tags ?? [],
    postedAgo: (raw.posted_text || "").replace(/^Đăng\s+/, ""),
    postedText: raw.posted_text || "",
    detail: raw.job_detail ?? null,
    hot: (raw._salary_max ?? salaryParsed.max ?? 0) >= 50000000,
  };
}

// ---- main ----
function main() {
  const raw = JSON.parse(readFileSync(RAW_FILE, "utf8"));
  console.log(`Loaded ${raw.length} crawled jobs`);

  // de-duplicate by source_job_id (same job may appear in multiple categories)
  const seen = new Set();
  const unique = raw.filter((j) => {
    if (!j.source_job_id || seen.has(j.source_job_id)) return false;
    seen.add(j.source_job_id);
    return true;
  });
  console.log(`→ ${unique.length} unique after dedup`);

  // sort by posted date (newest first) then limit
  const normalized = unique.map(normalizeJob).slice(0, LIMIT);

  writeFileSync(OUT_FILE, JSON.stringify(normalized, null, 2));
  console.log(`✓ wrote ${normalized.length} jobs → ${OUT_FILE.pathname}`);

  // stats
  const cities = {};
  normalized.forEach(
    (j) => (cities[j.location] = (cities[j.location] || 0) + 1),
  );
  console.log(
    "\nTop cities:",
    Object.entries(cities)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([c, n]) => `${c} (${n})`)
      .join(", "),
  );
}

main();
