/**
 * Synthetic job generator — produces realistic Vietnamese job postings from
 * real TopCV reference data (categories, cities, salary ranges, experience
 * levels, company name components, per-category title pools).
 *
 * Output: data/jobs-raw.json (same format as crawl.js output) → run
 * transform.js to convert to seed.sql.
 *
 * Run:  node generate.js              (default 5000 jobs)
 *       node generate.js --count=1000
 */
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  CATEGORIES,
  SALARY_RANGES,
  EXPERIENCE_LEVELS,
  JOB_TYPES,
  WORK_MODES,
  CITIES,
  CITY_WEIGHTS,
  COMPANY_CORES,
  COMPANY_PREFIXES,
  COMPANY_SUFFIXES,
  TITLE_FAMILIES,
  CATEGORY_FAMILY,
} from "./reference.js";
import {
  DETAIL_FAMILIES,
  FAMILY_TO_DETAIL,
  COMMON_BENEFITS,
  WORKING_HOURS,
} from "./reference-descriptions.js";

// ---- CLI ----
const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const m = a.match(/^--([^=]+)=(.*)$/);
    return m ? [m[1], m[2]] : [a.slice(2), "1"];
  }),
);
const PER_CATEGORY = parseInt(args.perCategory ?? "500", 10);

// ---- seeded RNG (deterministic so re-runs are reproducible) ----
let _seed = 20260708;
function rng() {
  // mulberry32
  _seed |= 0;
  _seed = (_seed + 0x6d2b79f5) | 0;
  let t = Math.imul(_seed ^ (_seed >>> 15), 1 | _seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}
const pick = (arr) => arr[Math.floor(rng() * arr.length)];
const chance = (p) => rng() < p;

/** Weighted pick. items: [{...,weight}] or key→weight map + items */
function weightedPick(items, weightFn) {
  const total = items.reduce((s, it) => s + weightFn(it), 0);
  let r = rng() * total;
  for (const it of items) {
    r -= weightFn(it);
    if (r <= 0) return it;
  }
  return items[items.length - 1];
}

// ---- company name generation ----
const usedCompanies = new Map(); // name → id, for reuse

function makeCompany() {
  const prefix = pick(COMPANY_PREFIXES);
  // 1-3 core name components joined
  const nParts = 1 + Math.floor(rng() * 2);
  const parts = [];
  for (let i = 0; i < nParts; i++) parts.push(pick(COMPANY_CORES));
  const suffix = pick(COMPANY_SUFFIXES);
  const body = [...new Set(parts)].join(" ");
  const name = [prefix, body, suffix].filter(Boolean).join(" ");
  return name.trim();
}

function getOrCreateCompany() {
  // ~70% chance to reuse an existing company (realistic: big companies post many jobs)
  if (usedCompanies.size > 30 && chance(0.7)) {
    const names = [...usedCompanies.keys()];
    return pick(names);
  }
  let name = makeCompany();
  let guard = 0;
  while (usedCompanies.has(name) && guard++ < 5) name = makeCompany();
  if (!usedCompanies.has(name)) usedCompanies.set(name, usedCompanies.size + 1);
  return name;
}

// ---- city generation ----
function makeCity() {
  return weightedPick(CITIES, (c) => CITY_WEIGHTS[c] ?? 1);
}
function makeLocationText(city) {
  if (chance(0.15)) return `${city} & ${1 + Math.floor(rng() * 10)} nơi khác`;
  return city;
}

// ---- salary generation ----
function makeSalary() {
  const r = weightedPick(SALARY_RANGES, (s) =>
    s.label === "Thoả thuận" ? 12 : s.label.startsWith("Từ") ? 3 : 5,
  );
  return r;
}
function salaryToText(r) {
  if (r.min === null) return "Thoả thuận";
  if (r.max === null) return `Từ ${Math.round(r.min / 1000000)} triệu`;
  return `${Math.round(r.min / 1000000)} - ${Math.round(r.max / 1000000)} triệu`;
}

// ---- experience / tags ----
function makeExperienceTags(exp) {
  const tags = [`${exp.label} kinh nghiệm`];
  return tags;
}

// ---- posted date ----
function makePostedText() {
  const r = rng();
  if (r < 0.4) return `Đăng ${1 + Math.floor(rng() * 6)} ngày trước`;
  if (r < 0.8) return `Đăng ${1 + Math.floor(rng() * 3)} tuần trước`;
  return `Đăng 1 tháng trước`;
}

// ---- job detail (rich structured content like TopCV) ----
/** Shuffle a copy (Fisher-Yates) without mutating the original. */
function shuffled(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/** Build a structured job-detail object for one job, mixing family pools. */
function makeJobDetail(familyKey, exp, education) {
  const detailKey = FAMILY_TO_DETAIL[familyKey] ?? "other";
  const fam = DETAIL_FAMILIES[detailKey] ?? DETAIL_FAMILIES.other;

  // pick 6-10 responsibilities, 4-7 requirements, 5-7 benefits
  const respN = 6 + Math.floor(rng() * 5);
  const reqN = 4 + Math.floor(rng() * 4);
  const benN = 5 + Math.floor(rng() * 3);

  const responsibilities = shuffled(fam.responsibilities).slice(0, respN);
  const requirements = shuffled(fam.requirements).slice(0, reqN);
  // merge family-specific + common benefits, dedup, shuffle
  const benefitPool = [
    ...new Set([...(fam.extra_benefits || []), ...COMMON_BENEFITS]),
  ];
  const benefits = shuffled(benefitPool).slice(0, benN);

  return {
    mo_ta_cong_viec: responsibilities,
    yeu_cau_ung_vien: requirements,
    quyen_loi: benefits,
    thoi_gian_lam_viec: pick(WORKING_HOURS),
    yeu_cau_kinh_nghiem: exp.label,
    yeu_cau_bang_cap: education,
  };
}

// ---- main ----
function main() {
  console.log(
    `Generating ${PER_CATEGORY} jobs/category × ${CATEGORIES.length} categories = ${PER_CATEGORY * CATEGORIES.length} total...\n`,
  );

  const jobs = [];
  let jobSeq = 0;

  for (const [slug, name] of CATEGORIES) {
    const family = CATEGORY_FAMILY[slug];
    const titlePool =
      TITLE_FAMILIES[family] ?? TITLE_FAMILIES["nhom-nghe-khac-cr899"];

    for (let i = 0; i < PER_CATEGORY; i++) {
      jobSeq++;
      const company = getOrCreateCompany();
      const city = makeCity();
      const salary = makeSalary();
      const exp = pick(EXPERIENCE_LEVELS);
      const jobType = weightedPick(JOB_TYPES, (t) =>
        t.enum === "FULL_TIME" ? 80 : t.enum === "PART_TIME" ? 12 : 8,
      );
      const workMode = weightedPick(WORK_MODES, (w) => w.weight);
      const posted = makePostedText();

      // Build a varied title: base title + occasional suffix (level/location/income/remote)
      const baseTitle = pick(titlePool);
      const variations = [];
      if (chance(0.15)) {
        variations.push(pick(["Junior", "Senior", "Fresher", "Lead"]));
      }
      if (chance(0.18)) {
        const loc =
          city === "Hồ Chí Minh"
            ? "TP.HCM"
            : city === "Hà Nội"
              ? "Hà Nội"
              : null;
        if (loc) variations.push(loc);
      }
      if (chance(0.12)) variations.push("Thu Nhập Hấp Dẫn");
      if (chance(0.08)) variations.push("Upto 50 Triệu");
      if (chance(0.06)) variations.push("Remote");
      if (chance(0.05)) variations.push("Không Yêu Cầu Kinh Nghiệm");
      const jobTitle =
        variations.length > 0
          ? `${baseTitle} - ${variations.join(" - ")}`
          : baseTitle;

      // Education requirement (varies by experience level & job type)
      const education =
        jobType.enum === "INTERNSHIP"
          ? pick(["Sinh viên năm cuối", "Tốt nghiệp Cao đẳng trở lên"])
          : exp.enum === "INTERN" || exp.enum === "FRESHER"
            ? pick([
                "Tốt nghiệp Cao đẳng/Đại học",
                "Tốt nghiệp Đại học trở lên",
              ])
            : pick(["Tốt nghiệp Đại học trở lên", "Đại học trở lên"]);

      // Rich structured job detail (rendered on View Job Details page)
      const jobDetail = makeJobDetail(family, exp, education);

      jobs.push({
        source: "synthetic",
        source_job_id: `SYN-${String(jobSeq).padStart(5, "0")}`,
        category_slug: slug,
        category_name: name,
        job_title: jobTitle,
        company_name: company,
        company_url: null,
        company_logo: null,
        salary_text: salaryToText(salary),
        location_text: makeLocationText(city),
        experience_tags: makeExperienceTags(exp),
        posted_text: posted,
        detail_url: null,
        // extra fields for transform.js to read
        _work_mode: workMode.enum,
        _job_type: jobType.enum,
        _experience_enum: exp.enum,
        _salary_min: salary.min,
        _salary_max: salary.max,
        _is_negotiable: salary.min === null,
        job_detail: jobDetail,
        crawled_at: new Date().toISOString(),
      });
    }
  }

  // output
  const output = jobs;
  const OUT = fileURLToPath(new URL("./data/jobs-raw.json", import.meta.url));
  writeFileSync(OUT, JSON.stringify(output, null, 2));

  // ---- stats ----
  console.log(
    `✓ Generated ${output.length} jobs (${PER_CATEGORY}/category × ${CATEGORIES.length} categories)`,
  );
  console.log(`  Unique employers: ${usedCompanies.size}`);
  console.log(`  Deterministic seed: 20260708 (reproducible)\n`);

  const breakdown = (key) => {
    const m = {};
    for (const j of output) {
      const v = j[key];
      m[v] = (m[v] || 0) + 1;
    }
    return m;
  };
  console.log("Work mode:", breakdown("_work_mode"));
  console.log("Job type: ", breakdown("_job_type"));
  console.log("Negotiable:", breakdown("_is_negotiable"));
  console.log("\nNext step: node transform.js  →  data/seed.sql");
}

main();
