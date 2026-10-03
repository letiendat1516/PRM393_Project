/**
 * Deletes every doc with source='crawl' from jobs/ and employerProfiles/.
 * Safe counterpart to import-firestore.js — restores Firestore to pre-import state.
 *
 * Usage: same auth story as import-firestore.js.
 *   node clear-crawl.js --dry      # count only
 *   node clear-crawl.js            # actually delete
 */
import { existsSync } from "node:fs";
import { initializeApp, cert, applicationDefault } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const PROJECT_ID = "jobhub-prm393-g3";
const DEFAULT_SA = new URL("./firebase-admin-sa.json", import.meta.url);
const args = process.argv.slice(2);
const DRY = args.includes("--dry");
const positionalSa = args.find(
  (a) => !a.startsWith("--") && a.toLowerCase().endsWith(".json"),
);
const SA_PATH =
  positionalSa ||
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  (existsSync(DEFAULT_SA) ? DEFAULT_SA.pathname.replace(/^\//, "") : null);

if (!SA_PATH && !DRY) {
  console.error(
    "No service account JSON found. See import-firestore.js header.",
  );
  process.exit(2);
}

initializeApp({
  credential: SA_PATH ? cert(SA_PATH) : applicationDefault(),
  projectId: PROJECT_ID,
});
const db = getFirestore();

async function deleteWhereSource(col) {
  const q = db.collection(col).where("source", "==", "crawl");
  let total = 0;
  while (true) {
    const snap = await q.limit(500).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    if (!DRY) await batch.commit();
    total += snap.size;
    console.log(
      `  ${col}: ${DRY ? "would delete" : "deleted"} ${total} so far...`,
    );
    if (DRY) break; // single page probe
  }
  return total;
}

(async () => {
  const jobs = await deleteWhereSource("jobs");
  const emps = await deleteWhereSource("employerProfiles");
  console.log(
    `\n${DRY ? "DRY" : "DONE"}: jobs=${jobs}, employerProfiles=${emps}`,
  );
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
