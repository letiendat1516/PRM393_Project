/**
 * Imports crawl-topcv/data/jobs-raw.json → Firestore (project jobhub-prm393-g3).
 *
 * Writes:
 *   employerProfiles/{crawl-slug}           (de-duplicated per company_name)
 *   jobs/{crawl-SYN-00001}                  (one per raw job, source='crawl')
 *
 * Auth:
 *   Needs a Firebase Admin service account JSON. Download from
 *   console.firebase.google.com → Project Settings → Service accounts →
 *   Generate new private key. Save as ./firebase-admin-sa.json (gitignored).
 *
 * Usage:
 *   node import-firestore.js --dry           # print one doc + counts, no write
 *   node import-firestore.js                 # full import, uses ./firebase-admin-sa.json
 *   node import-firestore.js /path/to/sa.json
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json node import-firestore.js
 */
import { readFileSync, existsSync } from "node:fs";
import { initializeApp, cert, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

const PROJECT_ID = "jobhub-prm393-g3";
const DEFAULT_SA = new URL("./firebase-admin-sa.json", import.meta.url);
const RAW_FILE = new URL("./data/jobs-raw.json", import.meta.url);

const args = process.argv.slice(2);
const DRY = args.includes("--dry");
const positionalSa = args.find(
  (a) => !a.startsWith("--") && (a.endsWith(".json") || a.endsWith(".JSON")),
);
const SA_PATH =
  positionalSa ||
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  (existsSync(DEFAULT_SA) ? DEFAULT_SA.pathname.replace(/^\//, "") : null);

// ── Diacritics + tokenize (mirror lib/shared/models/job_model.dart:380) ──
const DIAC_FROM =
  "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ";
const DIAC_TO =
  "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd";
function stripDiacritics(s) {
  let out = "";
  for (const ch of s) {
    const i = DIAC_FROM.indexOf(ch);
    out += i >= 0 ? DIAC_TO[i] : ch;
  }
  return out;
}
function tokenize(title, company = "", category = "") {
  const text = `${title} ${company} ${category}`.toLowerCase();
  const stripped = stripDiacritics(text);
  const words = stripped
    .split(/[^a-z0-9+#.]+/)
    .filter((w) => w.length >= 2);
  const out = new Set();
  for (const w of words) {
    out.add(w);
    for (let i = 2; i < w.length && i <= 6; i++) out.add(w.slice(0, i));
  }
  return [...out].slice(0, 60);
}

function employerUidFor(name) {
  const slug = stripDiacritics(name.toLowerCase())
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 40);
  return `crawl-${slug}`;
}

// ── Build docs ─────────────────────────────────────────────────────────
const RAW = JSON.parse(readFileSync(RAW_FILE, "utf8"));
console.log(`Loaded ${RAW.length} raw jobs from ${RAW_FILE.pathname}`);

const employers = new Map();
const jobDocs = [];

const now = new Date();
for (const r of RAW) {
  const uid = employerUidFor(r.company_name);
  if (!employers.has(uid)) {
    employers.set(uid, {
      uid,
      companyName: r.company_name,
      city: r.location_text || "",
      industry: r.category_name || "",
      logoUrl: r.company_logo || null,
      website: r.company_url || null,
      isVerified: true,
      openPositions: 0,
      source: "crawl",
    });
  }
  const emp = employers.get(uid);
  emp.openPositions++;
  if (!emp.city && r.location_text) emp.city = r.location_text;

  const createdAt = r.crawled_at ? new Date(r.crawled_at) : now;
  const deadline = new Date(createdAt.getTime() + 60 * 86_400_000); // +60 days
  const jobId = `crawl-${r.source_job_id || `${jobDocs.length + 1}`.padStart(5, "0")}`;

  jobDocs.push({
    id: jobId,
    data: {
      jobId,
      employerId: uid,
      employerName: r.company_name,
      employerLogoUrl: r.company_logo || null,
      employerCity: r.location_text || "",
      employerWebsite: r.company_url || null,
      categoryName: r.category_name || null,
      jobTitle: r.job_title,
      description: {
        moTaCongViec: r.job_detail?.mo_ta_cong_viec || [],
        yeuCauUngVien: r.job_detail?.yeu_cau_ung_vien || [],
        quyenLoi: r.job_detail?.quyen_loi || [],
        thoiGianLamViec: r.job_detail?.thoi_gian_lam_viec || "",
        yeuCauKinhNghiem: r.job_detail?.yeu_cau_kinh_nghiem || "",
        yeuCauBangCap: r.job_detail?.yeu_cau_bang_cap || "Không yêu cầu",
      },
      salaryMin: r._salary_min ?? null,
      salaryMax: r._salary_max ?? null,
      salaryCurrency: "VND",
      salaryPeriod: "MONTH",
      isSalaryNegotiable: !!r._is_negotiable,
      city: r.location_text || "",
      country: "Vietnam",
      workMode: r._work_mode || "ONSITE",
      jobType: r._job_type || "FULL_TIME",
      experienceLevel: r._experience_enum || "FRESHER",
      positionsAvailable: 1,
      applicationDeadline: Timestamp.fromDate(deadline),
      status: "OPEN",
      isApproved: true,
      requiredSkills: [],
      titleTokens: tokenize(r.job_title, r.company_name, r.category_name),
      applicationsCount: 0,
      source: "crawl",
      createdAt: Timestamp.fromDate(createdAt),
      updatedAt: FieldValue.serverTimestamp(),
    },
  });
}

console.log(`→ ${employers.size} unique employers, ${jobDocs.length} jobs`);

if (DRY) {
  console.log("\n=== DRY RUN — first employer ===");
  console.log(JSON.stringify([...employers.values()][0], null, 2));
  console.log("\n=== DRY RUN — first job ===");
  console.log(JSON.stringify(jobDocs[0], null, 2));
  console.log("\nNo writes performed.");
  process.exit(0);
}

if (!SA_PATH) {
  console.error(
    "\n[ERROR] No service account JSON found.\n" +
      "  1. Firebase Console → Project Settings → Service accounts → Generate new private key\n" +
      "  2. Save as ./firebase-admin-sa.json  (same folder as this script)\n" +
      "  3. Re-run: node import-firestore.js\n",
  );
  process.exit(2);
}

initializeApp({
  credential: SA_PATH ? cert(SA_PATH) : applicationDefault(),
  projectId: PROJECT_ID,
});
const db = getFirestore();

async function commitBatch(label, docs, docRef) {
  for (let i = 0; i < docs.length; i += 500) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + 500);
    for (const d of chunk) batch.set(docRef(d), docRef(d, true), { merge: true });
    await batch.commit();
    console.log(`  ${label} ${i + chunk.length}/${docs.length}`);
  }
}

async function run() {
  const t0 = Date.now();
  console.log(`\nImporting into project ${PROJECT_ID}...`);
  // employers
  for (let i = 0; i < [...employers.values()].length; i += 500) {
    const list = [...employers.values()].slice(i, i + 500);
    const batch = db.batch();
    for (const e of list) {
      batch.set(db.collection("employerProfiles").doc(e.uid), e, {
        merge: true,
      });
    }
    await batch.commit();
    console.log(
      `  employers ${i + list.length}/${employers.size}`,
    );
  }
  // jobs
  for (let i = 0; i < jobDocs.length; i += 500) {
    const list = jobDocs.slice(i, i + 500);
    const batch = db.batch();
    for (const j of list) {
      batch.set(db.collection("jobs").doc(j.id), j.data, { merge: true });
    }
    await batch.commit();
    console.log(`  jobs ${i + list.length}/${jobDocs.length}`);
  }
  console.log(
    `\n✓ Done in ${((Date.now() - t0) / 1000).toFixed(1)}s. ` +
      `Wrote ${employers.size} employerProfiles + ${jobDocs.length} jobs ` +
      `(source='crawl').`,
  );
}

run().catch((e) => {
  console.error("\n[FATAL]", e.message || e);
  process.exit(1);
});
