/**
 * TopCV → JobHub crawler (Playwright).
 *
 * Collects ~5000 job listings spread evenly across job categories,
 * saves raw JSON to data/jobs-raw.json. Polite: rate-limited, fresh context
 * per page load (isolates crashes), resumable.
 *
 * Run:  node crawl.js                (full run, ~5 min)
 *       node crawl.js --pages=2      (quick test: 2 pages per category)
 *       node crawl.js --cats=3       (only first 3 categories)
 *
 * Output: data/jobs-raw.json
 *         data/progress.json   (resumable state)
 *
 * Architecture notes:
 *  - Fresh browser CONTEXT per page load → a crashed page never poisons the
 *    next one (TopCV/Cloudflare occasionally crashes a tab).
 *  - Browser is restarted by main() if it becomes unreachable.
 *  - Full Chromium (not headless-shell) + navigator.webdriver patch → passes
 *    Cloudflare "Just a moment" challenge.
 */
import { chromium } from "playwright";
import { writeFileSync, readFileSync, existsSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import {
  CATEGORIES,
  MAX_PAGES_PER_CATEGORY,
  DELAY_BETWEEN_PAGES_MS,
  DELAY_BETWEEN_CATEGORIES_MS,
  MAX_RETRIES_PER_PAGE,
  NAV_TIMEOUT_MS,
  BASE_URL,
} from "./categories.js";

const UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

const DATA_DIR = new URL("./data/", import.meta.url).pathname.replace(
  /^\//,
  "",
);
const OUTPUT_FILE = `${DATA_DIR}jobs-raw.json`;
const PROGRESS_FILE = `${DATA_DIR}progress.json`;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---- CLI args ----
const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const m = a.match(/^--([^=]+)=(.*)$/);
    return m ? [m[1], m[2]] : [a.slice(2), "1"];
  }),
);
const maxCats = args.cats ? parseInt(args.cats, 10) : CATEGORIES.length;
const pagesPerCatOverride = args.pages ? parseInt(args.pages, 10) : null;

// ---------- browser / context ----------
async function launchBrowser() {
  // Headed mode (headless: false) so the user can solve Cloudflare /
  // Turnstile challenges BY HAND when they appear in the browser window.
  console.log(
    "[browser] launching HEADED — solve any Cloudflare challenge manually in the window",
  );
  return chromium.launch({
    headless: false,
    args: [
      "--disable-blink-features=AutomationControlled",
      "--no-sandbox",
      "--disable-dev-shm-usage",
    ],
  });
}

/** Create a fresh stealth context (one per category, holds CF cookie).
 *  Pages are created/closed per-load by the caller. */
async function newContext(browser) {
  const context = await browser.newContext({
    userAgent: UA,
    viewport: { width: 1366, height: 768 },
    locale: "vi-VN",
    extraHTTPHeaders: { "accept-language": "vi-VN,vi;q=0.9,en;q=0.8" },
  });
  await context.addInitScript(() => {
    Object.defineProperty(navigator, "webdriver", { get: () => undefined });
  });
  return context;
}

// ---------- page parsing ----------
async function waitForJobs(page) {
  try {
    await page.waitForSelector(".job-item-search-result", {
      timeout: NAV_TIMEOUT_MS,
    });
    await page.waitForTimeout(1500);
    return true;
  } catch {
    return false;
  }
}

async function extractJobs(page, categorySlug, categoryName) {
  return page.$$eval(
    ".job-item-search-result",
    (cards, ctx) => {
      const clean = (s) => (s || "").replace(/\s+/g, " ").trim();
      return cards
        .map((card) => {
          const text = (sel) => clean(card.querySelector(sel)?.textContent);
          const attr = (sel, a) =>
            card.querySelector(sel)?.getAttribute(a) ?? null;

          // posted date: an .icon span starting with "Đăng"
          const icons = Array.from(card.querySelectorAll(".icon"));
          const postedMatch =
            icons
              .map((e) => clean(e.textContent))
              .find((t) => t.startsWith("Đăng")) || "";
          const postedRaw = postedMatch
            .replace(/Ứng tuyển.*$/i, "")
            .replace(/Ứng.{0,3}tuyển/gi, "")
            .trim();

          const salary =
            text(".box-right .title-salary") ||
            text(".salary") ||
            text(".box-right .label-content");
          const location = text(".city-text");
          const tags = Array.from(
            card.querySelectorAll(".box-icon .item-tag"),
          ).map((e) => clean(e.textContent));

          return {
            source: "topcv",
            source_job_id: card.getAttribute("data-job-id"),
            category_slug: ctx.slug,
            category_name: ctx.name,
            job_title: text(".title a span") || text(".title a"),
            company_name: text(".company-name"),
            company_url: attr(".company", "href"),
            company_logo:
              attr(".avatar img", "data-src") || attr(".avatar img", "src"),
            salary_text: salary,
            location_text: location,
            experience_tags: tags,
            posted_text: postedRaw,
            detail_url: attr(".title a", "href"),
            crawled_at: new Date().toISOString(),
          };
        })
        .filter((j) => j.job_title && j.detail_url);
    },
    { slug: categorySlug, name: categoryName },
  );
}

/** Detect the total number of job listings on the page so we can compute
 *  total pages. TopCV shows a counter like "Tìm thấy 51.533 tin đăng" or
 *  "Tuyển dụng 5535 việc làm". Returns total job count, or null if unknown. */
async function detectTotalJobs(page) {
  return page.evaluate(() => {
    const body = document.body.innerText || "";
    // patterns: "Tìm thấy 51.533 tin đăng" / "5535 việc làm" / "12.345"
    const patterns = [
      /Tìm thấy\s+([\d.]+)\s+tin đăng/i,
      /([\d.]+)\s+việc làm/i,
      /([\d.]+)\s+tin tuyển dụng/i,
    ];
    for (const re of patterns) {
      const m = body.match(re);
      if (m) return parseInt(m[1].replace(/\./g, ""), 10);
    }
    return null;
  });
}

/** Fetch one page in a fresh PAGE within the given context.
 *  Reusing the context keeps Cloudflare's clearance cookie alive across
 *  pages. When a CF challenge appears and the browser is HEADED, we wait
 *  up to CAPTCHA_WAIT_MS for the user to solve it manually. */
const CAPTCHA_WAIT_MS = 180000; // 3 min for manual solve
const CAPTCHA_POLL_MS = 3000;

async function crawlPage(context, slug, name, pageNum) {
  const url = `${BASE_URL}/tim-viec-lam-${slug}?page=${pageNum}`;
  const page = await context.newPage();
  try {
    await page.goto(url, {
      waitUntil: "domcontentloaded",
      timeout: NAV_TIMEOUT_MS,
    });
    let ok = await waitForJobs(page);
    if (!ok) {
      // CF challenge / Turnstile interstitial detected.
      console.log(`    ⚠️  Cloudflare challenge detected on page ${pageNum}.`);
      console.log(
        `        → If the browser window is open, SOLVE the challenge manually,`,
      );
      console.log(`          then wait — crawling resumes automatically.`);
      // Poll for up to CAPTCHA_WAIT_MS for the challenge to clear
      // (either auto-resolved or solved by the user in the headed window).
      const deadline = Date.now() + CAPTCHA_WAIT_MS;
      while (!ok && Date.now() < deadline) {
        await page.waitForTimeout(CAPTCHA_POLL_MS);
        ok = await waitForJobs(page);
      }
      if (!ok) throw new Error("CF challenge not solved within 3 min");
      console.log(`    ✅ challenge cleared, continuing...`);
    }
    const jobs = await extractJobs(page, slug, name);
    // Detect total job count (for auto-pagination) on every page; cheap.
    const totalJobs = await detectTotalJobs(page);
    return { jobs, totalJobs };
  } finally {
    try {
      await page.close();
    } catch {}
  }
}

async function crawlCategory(browser, slug, name, resumePage = 1) {
  const jobs = [];
  // Upper bound on pages (safety). pagesPerCatOverride (--pages=N) caps it
  // further for quick tests. Real total is auto-detected from page 1.
  const hardCap = pagesPerCatOverride ?? MAX_PAGES_PER_CATEGORY;

  if (resumePage > hardCap) {
    console.log(`  [${slug}] already complete, skipping.`);
    return jobs;
  }

  // ONE context per category — carries Cloudflare clearance cookie across pages.
  const context = await newContext(browser);

  // Dynamic total — set after we load page 1 and read the "Tìm thấy N" counter.
  let detectedTotalJobs = null;
  let detectedTotalPages = hardCap;

  for (let p = resumePage; p <= detectedTotalPages; p++) {
    const progressLabel =
      detectedTotalJobs !== null
        ? `page ${p}/${detectedTotalPages} (~${detectedTotalJobs} jobs total)`
        : `page ${p}`;
    console.log(`  [${slug}] ${progressLabel}`);

    let success = false;
    for (
      let attempt = 1;
      attempt <= MAX_RETRIES_PER_PAGE && !success;
      attempt++
    ) {
      try {
        const { jobs: pageJobs, totalJobs } = await crawlPage(
          context,
          slug,
          name,
          p,
        );

        // On first successful load, lock in the real total pages.
        if (detectedTotalJobs === null && totalJobs !== null) {
          detectedTotalJobs = totalJobs;
          detectedTotalPages = Math.min(
            hardCap,
            Math.max(1, Math.ceil(totalJobs / 50)),
          );
          console.log(
            `    ℹ️  category has ~${totalJobs} jobs → ${detectedTotalPages} pages (cap ${hardCap})`,
          );
        }

        if (pageJobs.length === 0) {
          console.log(`    ↳ empty page, category exhausted.`);
          success = true;
          // empty page means we're past the end
          detectedTotalPages = p - 1;
        } else {
          jobs.push(...pageJobs);
          console.log(`    ↳ +${pageJobs.length} jobs (total: ${jobs.length})`);
          success = true;
        }
      } catch (err) {
        console.log(`    ↳ attempt ${attempt} failed: ${err.message}`);
        if (
          err.message.includes("Target page") ||
          err.message.includes("crashed") ||
          err.message.includes("closed") ||
          err.message.includes("Browser")
        ) {
          throw new Error(`browser unreachable: ${err.message}`);
        }
        if (attempt < MAX_RETRIES_PER_PAGE) await sleep(8000 * attempt);
      }
    }

    if (!success) {
      console.log(`    ↳ giving up on page ${p}, moving on.`);
      break;
    }

    saveProgress(slug, p);
    if (p < detectedTotalPages) await sleep(DELAY_BETWEEN_PAGES_MS);
  }

  try {
    await context.close();
  } catch {}
  return jobs;
}

// ---------- progress / resume ----------
function loadProgress() {
  if (existsSync(PROGRESS_FILE)) {
    try {
      return JSON.parse(readFileSync(PROGRESS_FILE, "utf8"));
    } catch {
      return {};
    }
  }
  return {};
}

function saveProgress(slug, page) {
  const prog = loadProgress();
  prog[slug] = page;
  writeFileSync(PROGRESS_FILE, JSON.stringify(prog, null, 2));
}

function loadExistingJobs() {
  if (existsSync(OUTPUT_FILE)) {
    try {
      return JSON.parse(readFileSync(OUTPUT_FILE, "utf8"));
    } catch {
      return [];
    }
  }
  return [];
}

// ---------- main ----------
async function main() {
  await mkdir(DATA_DIR, { recursive: true });

  const selectedCats = CATEGORIES.slice(0, maxCats);
  console.log(`\n=== TopCV → JobHub crawler ===`);
  console.log(`Categories: ${selectedCats.length}`);
  console.log(
    `Pages/category: ${pagesPerCatOverride ?? PAGES_PER_CATEGORY} (${selectedCats.length} categories × ${(pagesPerCatOverride ?? PAGES_PER_CATEGORY) * 50} jobs)`,
  );
  console.log(`Output: ${OUTPUT_FILE}\n`);

  let browser = await launchBrowser();
  const allJobs = loadExistingJobs();
  const progress = loadProgress();
  const maxPagesPerCat = pagesPerCatOverride ?? PAGES_PER_CATEGORY;

  try {
    for (const [slug, name] of selectedCats) {
      const startPage = (progress[slug] ?? 0) + 1;
      if (startPage > maxPagesPerCat) {
        console.log(`\n--- ${name} (${slug}): already complete, skipping ---`);
        continue;
      }
      console.log(`\n--- ${name} (${slug}) ---`);

      let jobs = [];
      try {
        jobs = await crawlCategory(browser, slug, name, startPage);
      } catch (err) {
        // Browser crashed → restart and retry this category once.
        console.log(
          `--- ${name}: browser error (${err.message}), restarting ---`,
        );
        try {
          await browser.close();
        } catch {}
        await sleep(5000);
        browser = await launchBrowser();
        try {
          jobs = await crawlCategory(browser, slug, name, startPage);
        } catch (err2) {
          console.log(
            `--- ${name}: still failing (${err2.message}), skipping ---`,
          );
        }
      }

      allJobs.push(...jobs);
      console.log(
        `--- ${name}: collected ${jobs.length} (grand total: ${allJobs.length}) ---`,
      );
      writeFileSync(OUTPUT_FILE, JSON.stringify(allJobs, null, 2));
      console.log(`  saved → ${OUTPUT_FILE}`);

      await sleep(DELAY_BETWEEN_CATEGORIES_MS);
    }
  } finally {
    try {
      await browser.close();
    } catch {}
  }

  // de-duplicate by source_job_id
  const seen = new Set();
  const deduped = allJobs.filter((j) => {
    if (!j.source_job_id || seen.has(j.source_job_id)) return false;
    seen.add(j.source_job_id);
    return true;
  });
  writeFileSync(OUTPUT_FILE, JSON.stringify(deduped, null, 2));

  console.log(`\n=== DONE ===`);
  console.log(`Total raw jobs: ${allJobs.length}`);
  console.log(`After dedup:    ${deduped.length}`);
  console.log(`Output:         ${OUTPUT_FILE}`);

  const byCat = {};
  for (const j of deduped)
    byCat[j.category_slug] = (byCat[j.category_slug] || 0) + 1;
  console.log(`\nPer-category:`);
  for (const [slug, name] of selectedCats) {
    console.log(`  ${name.padEnd(28)} ${byCat[slug] || 0}`);
  }
}

main().catch((err) => {
  console.error("FATAL:", err);
  process.exit(1);
});
