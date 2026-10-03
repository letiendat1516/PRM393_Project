/**
 * Probe a TopCV company page to discover selectors for:
 * logo, description, industry, employee count, website, etc.
 */
import { chromium } from 'playwright';

const COMPANY_URL =
  'https://www.topcv.vn/cong-ty/cong-ty-tnhh-dao-tao-va-tu-van-giao-duc-worklish/261111.html';

async function main() {
  const browser = await chromium.launch({
    headless: false,
    args: ['--disable-blink-features=AutomationControlled', '--no-sandbox'],
  });
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    viewport: { width: 1366, height: 768 },
    locale: 'vi-VN',
  });
  await context.addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
  });
  const page = await context.newPage();

  console.log('Navigating to company page...');
  await page.goto(COMPANY_URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(3000);

  const title = await page.title();
  console.log('Title:', title);

  // Try to find company info selectors
  const queries = [
    ['Logo img', '.logo-company img, .company-logo img, img[alt*="logo"]'],
    ['Company name', 'h1, .company-name, [class*="brand"]'],
    ['Description', '.company-description, .about, [class*="description"], [class*="about"]'],
    ['Industry', '.industry, .field, [class*="industry"], [class*="nganh"]'],
    ['Employee count', '.size, .scale, [class*="size"], [class*="scale"]'],
    ['Website', 'a[href*="http"]:not([href*="topcv"])'],
    ['Phone', 'a[href*="tel"], .phone, [class*="phone"]'],
    ['Address', '.address, [class*="address"], [class*="location"]'],
  ];

  console.log('\n=== SELECTOR SCAN ===');
  for (const [label, sel] of queries) {
    try {
      const el = page.locator(sel).first();
      const count = await el.count();
      const text = count > 0 ? (await el.textContent()).trim().slice(0, 100) : null;
      const src = count > 0 ? await el.getAttribute('src').catch(() => null) : null;
      const href = count > 0 ? await el.getAttribute('href').catch(() => null) : null;
      console.log(`  ${label}: sel="${sel}" → ${count ? 'FOUND' : 'NOT FOUND'}`, text ? `"${text}"` : '', src ? `src=${src.slice(0,60)}` : '', href ? `href=${href.slice(0,60)}` : '');
    } catch { console.log(`  ${label}: ERROR`); }
  }

  // Dump page body text (first 2000 chars) for manual inspection
  console.log('\n=== BODY SNIPPET ===');
  const body = await page.evaluate(() => document.body.innerText.slice(0, 2000));
  console.log(body);

  console.log('\nDone. Browser stays open for manual inspection. Close it to exit.');
  // Keep browser open so user can inspect manually
  await page.waitForTimeout(120000);
  await browser.close();
}
main().catch(e => { console.error(e); process.exit(1); });
