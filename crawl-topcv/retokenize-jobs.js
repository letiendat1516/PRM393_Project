/**
 * Re-tokenizes titleTokens for every job in Firestore so the index covers
 * title + company + categoryName (the original import only tokenised title
 * and company). Fixes "search 'IT' chỉ ra 19 jobs": the catalogue has 200+
 * jobs per IT-ish categoryName ("Backend Developer", "DevOps Engineer", …)
 * but their Vietnamese-only titles never produced the English role tokens
 * ("developer", "engineer", "backend") that the client-side synonym map
 * expands "IT" to. Adding the category words to each job's titleTokens
 * makes the arrayContainsAny query reach them.
 *
 * Usage:
 *   node retokenize-jobs.js --dry          # count + show 3 diffs, no writes
 *   node retokenize-jobs.js                # batched updates (500 per batch)
 */
import { initializeApp, cert } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const DRY = process.argv.includes("--dry");

initializeApp({
  credential: cert(
    "./jobhub-prm393-g3-firebase-adminsdk-fbsvc-759f69d63c.json",
  ),
  projectId: "jobhub-prm393-g3",
});
const db = getFirestore();

// Mirror of lib/shared/models/job_model.dart tokenize() with the extra
// `category` param — kept identical to the Dart implementation so the Flutter
// client reproduces exactly the same tokens for new writes.
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
  const words = stripped.split(/[^a-z0-9+#.]+/).filter((w) => w.length >= 2);
  const out = new Set();
  for (const w of words) {
    out.add(w);
    for (let i = 2; i < w.length && i <= 6; i++) out.add(w.slice(0, i));
  }
  return [...out].slice(0, 60);
}

async function main() {
  console.log(`Fetching all jobs…`);
  const snap = await db.collection("jobs").get();
  console.log(`Loaded ${snap.size} jobs`);

  let changed = 0;
  let skipped = 0;
  let batch = db.batch();
  let batchCount = 0;
  let shown = 0;

  for (const d of snap.docs) {
    const j = d.data();
    const fresh = tokenize(
      j.jobTitle || "",
      j.employerName || "",
      j.categoryName || "",
    );
    const old = j.titleTokens || [];
    const same =
      old.length === fresh.length && old.every((t, i) => t === fresh[i]);
    if (same) {
      skipped++;
      continue;
    }

    if (DRY && shown < 3) {
      console.log(`\n[sample ${shown + 1}] ${j.jobTitle} || ${j.categoryName}`);
      console.log(`  old (${old.length}):   ${old.slice(0, 12).join(",")}`);
      console.log(`  new (${fresh.length}): ${fresh.slice(0, 12).join(",")}`);
      const added = fresh.filter((t) => !old.includes(t));
      console.log(`  + added: ${added.slice(0, 8).join(",")}`);
      shown++;
    }

    changed++;
    if (!DRY) {
      batch.update(d.ref, { titleTokens: fresh });
      batchCount++;
      if (batchCount >= 400) {
        await batch.commit();
        process.stdout.write(`.`);
        batch = db.batch();
        batchCount = 0;
      }
    }
  }

  if (!DRY && batchCount > 0) {
    await batch.commit();
    process.stdout.write(`.`);
  }

  console.log(`\n\n${DRY ? "DRY RUN " : ""}Would update ${changed} jobs`);
  console.log(`Skipped (already up-to-date): ${skipped}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
