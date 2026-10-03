/**
 * Extract all TopCV job-category slugs from the search page sidebar.
 * Outputs a JS array of [slug, name] pairs to paste into categories.js.
 */
import { chromium } from "playwright";

const URL = "https://www.topcv.vn/tim-viec-lam-moi-nhat";
const UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

async function main() {
  const browser = await chromium.launch({
    headless: true,
    args: ["--disable-blink-features=AutomationControlled", "--no-sandbox"],
  });
  const context = await browser.newContext({
    userAgent: UA,
    viewport: { width: 1366, height: 768 },
    locale: "vi-VN",
  });
  await context.addInitScript(() => {
    Object.defineProperty(navigator, "webdriver", { get: () => undefined });
  });
  const page = await context.newPage();
  await page.goto(URL, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.waitForSelector(".job-item-search-result", { timeout: 60000 });
  await page.waitForTimeout(2000);

  // Extract category links: /tim-viec-lam-<slug>
  const cats = await page.$$eval('a[href*="/tim-viec-lam-"]', (els) => {
    const seen = new Set();
    const out = [];
    for (const e of els) {
      const href = e.getAttribute("href") || "";
      const m = href.match(/\/tim-viec-lam-([a-z0-9-]+)\b/i);
      if (!m) continue;
      const slug = m[1];
      if (["moi-nhat"].includes(slug)) continue; // skip the "newest" page itself
      if (seen.has(slug)) continue;
      seen.add(slug);
      const name = (e.textContent || "").trim().replace(/\s+/g, " ").slice(0, 60);
      out.push([slug, name]);
    }
    return out;
  });

  console.log(`Found ${cats.length} categories:\n`);
  for (const [slug, name] of cats) console.log(`  ['${slug}', '${name}'],`);

  await browser.close();
}
main().catch((e) => {
  console.error(e);
  process.exit(1);
});
