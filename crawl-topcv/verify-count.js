import { initializeApp, cert } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp({
  credential: cert("./jobhub-prm393-g3-firebase-adminsdk-fbsvc-759f69d63c.json"),
  projectId: "jobhub-prm393-g3",
});
const db = getFirestore();

const pub = await db
  .collection("jobs")
  .where("isApproved", "==", true)
  .where("status", "==", "OPEN")
  .count()
  .get();
const crawl = await db
  .collection("jobs")
  .where("source", "==", "crawl")
  .count()
  .get();
const emp = await db
  .collection("employerProfiles")
  .where("source", "==", "crawl")
  .count()
  .get();

console.log("jobs public (isApproved+OPEN):", pub.data().count);
console.log("jobs source=crawl:", crawl.data().count);
console.log("employerProfiles source=crawl:", emp.data().count);

const sample = await db
  .collection("jobs")
  .where("source", "==", "crawl")
  .limit(1)
  .get();
const d = sample.docs[0].data();
console.log(
  "\nsample job:",
  d.jobId,
  "|",
  d.jobTitle,
  "|",
  d.employerName,
  "|",
  d.city,
  "|",
  d.salaryMin + "-" + d.salaryMax,
);
console.log("titleTokens[0..5]:", d.titleTokens.slice(0, 6));
console.log("workMode/jobType/experience:", d.workMode, "/", d.jobType, "/", d.experienceLevel);
console.log("description.moTaCongViec.length:", d.description.moTaCongViec.length);
process.exit(0);
