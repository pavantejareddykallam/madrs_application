require("dotenv").config();

const functions = require("firebase-functions/v1"); // 1st-GEN SAFE
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();
const db = admin.firestore();

// Load SendGrid keys
const SENDGRID_KEY = process.env.SENDGRID_KEY;
const SENDGRID_FROM = process.env.SENDGRID_FROM;

sgMail.setApiKey(SENDGRID_KEY);

// --------------------------
// Helpers
// --------------------------
function getTodayDate() {
  const now = new Date(
    new Date().toLocaleString("en-US", { timeZone: "America/Chicago" })
  );
  return now.toISOString().split("T")[0];
}

async function sendEmail(to, subject, text) {
  if (!to) return;

  const msg = {
    to,
    from: SENDGRID_FROM,
    subject,
    text,
  };

  try {
    await sgMail.send(msg);
  } catch (e) {
    console.error("SendGrid Error:", e);
  }
}

async function sendPush(token, title, body) {
  if (!token) return;

  try {
    await admin.messaging().send({
      token,
      notification: { title, body }
    });
  } catch (e) {
    console.error("FCM error:", e);
  }
}

// ============================================================
// 1. Mark Not Responded — 10 AM
// ============================================================
exports.markNotResponded = functions
  .runWith({ failurePolicy: false }) // <- KEEP 1st GEN
  .pubsub.schedule("0 10 * * *")
  .timeZone("America/Chicago")
  .onRun(async () => {
    const today = getTodayDate();
    const users = await db.collection("Users").get();

    for (const doc of users.docs) {
      const uid = doc.id;
      const user = doc.data();

      const ref = db.collection("DailyStatus").doc(`${today}_${uid}`);
      const snap = await ref.get();

      const hasResponded = snap.exists && snap.data().responded === true;

      if (!hasResponded) {
        await ref.set(
          {
            userID: uid,
            date: today,
            responded: false,
            status: "not_responded",
            timestamp: admin.firestore.FieldValue.serverTimestamp()
          },
          { merge: true }
        );

        await sendPush(
          user.fcmToken,
          "MADRS Reminder",
          "Please complete today's MADRS + Sleep Diary."
        );
      }
    }

    return null;
  });

// ============================================================
// 2. 3-Hour Interval Reminders
// ============================================================
exports.threeHour = functions
  .runWith({ failurePolicy: false })
  .pubsub.schedule("0 13,16,19,22 * * *")
  .timeZone("America/Chicago")
  .onRun(async () => {
    const today = getTodayDate();
    const users = await db.collection("Users").get();

    for (const doc of users.docs) {
      const uid = doc.id;
      const user = doc.data();

      const ref = db.collection("DailyStatus").doc(`${today}_${uid}`);
      const snap = await ref.get();

      const responded = snap.exists && snap.data().responded === true;

      if (!responded) {
        await sendPush(
          user.fcmToken,
          "MADRS Reminder",
          "You still haven't completed today's MADRS."
        );
      }
    }

    return null;
  });

// ============================================================
// 3. Morning Email — 8 AM
// ============================================================
exports.morningEmail = functions
  .runWith({ failurePolicy: false })
  .pubsub.schedule("0 8 * * *")
  .timeZone("America/Chicago")
  .onRun(async () => {
    const today = getTodayDate();
    const users = await db.collection("Users").get();

    for (const doc of users.docs) {
      const uid = doc.id;
      const user = doc.data();
      const email = user.email;

      const ref = db.collection("DailyStatus").doc(`${today}_${uid}`);
      const snap = await ref.get();

      const responded = snap.exists && snap.data().responded === true;

      if (!responded) {
        await sendEmail(
          email,
          "MADRS Morning Reminder",
          "Good morning! Please complete today's MADRS questionnaire."
        );
      }
    }

    return null;
  });

// ============================================================
// 4. Evening Email — changeable schedule
// ============================================================
exports.eveningEmail = functions
  .runWith({ failurePolicy: false })
  .pubsub.schedule("35 15 * * *") // 3:35 PM CST
  .timeZone("America/Chicago")
  .onRun(async () => {
    const today = getTodayDate();
    const users = await db.collection("Users").get();

    for (const doc of users.docs) {
      const uid = doc.id;
      const user = doc.data();
      const email = user.email;

      const ref = db.collection("DailyStatus").doc(`${today}_${uid}`);
      const snap = await ref.get();

      const responded = snap.exists && snap.data().responded === true;

      if (!responded) {
        await sendEmail(
          email,
          "MADRS Evening Reminder",
          "This is your evening reminder to complete today's MADRS."
        );
      }
    }

    return null;
  });

// ============================================================
// Test Email Endpoint
// ============================================================
exports.testEmail = functions
  .runWith({ failurePolicy: false })
  .https.onRequest(async (req, res) => {
    try {
      await sgMail.send({
        to: "wordpairapp10@gmail.com",
        from: SENDGRID_FROM,
        subject: "Test Email from Firebase",
        text: "If you see this, SendGrid is working!",
      });

      res.send("Email sent!");
    } catch (err) {
      console.error("EMAIL ERROR:", err);
      res.status(500).send(err.toString());
    }
  });
