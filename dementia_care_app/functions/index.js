const functions = require("firebase-functions/v2");
const { Storage } = require("@google-cloud/storage");
const cors = require("cors")({ origin: true });

const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");


const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp(); 
const db = getFirestore();

const storage = new Storage({ projectId: "dementia-care-9bbf2" });
const bucketName = "dementia-care-9bbf2.firebasestorage.app";

// ✅ Generate signed URL
exports.getSignedUploadUrl = functions.https.onRequest({ region: "us-central1" }, (req, res) => {
  cors(req, res, async () => {
    const { filename, contentType } = req.body;
    if (!filename || !contentType) {
      return res.status(400).json({ error: "Missing filename or contentType" });
    }

    try {
      const file = storage.bucket(bucketName).file(filename);
      const [url] = await file.getSignedUrl({
        version: "v4",
        action: "write",
        expires: Date.now() + 15 * 60 * 1000,
        contentType: contentType,
      });
      return res.status(200).json({ signedUrl: url });
    } catch (error) {
      console.error("Error generating signed URL:", error);
      return res.status(500).json({ error: "Failed to generate signed URL" });
    }
  });
});

//  Dynamic Reminder Adjustments
exports.adjustReminderTimes = onSchedule("every 24 hours", async () => {
  console.log("⏰ Starting scheduled adjustment...");
  const trackingSnap = await db.collection("reminderTracking").get();
  if (trackingSnap.empty) {
    console.log("⚠️ No tracking data found.");
    return;
  }

  const grouped = {};
  trackingSnap.forEach(doc => {
    const d = doc.data();
    const key = `${d.patientId}_${d.reminderId}`;
    if (!grouped[key]) grouped[key] = [];
    grouped[key].push(d);
  });

  for (const key of Object.keys(grouped)) {
    const [patientId, reminderId] = key.split("_");
    const entries = grouped[key];

    const hourCounts = {};
    entries.forEach(e => {
      if (!e.actualTime) return;
      const date = new Date(e.actualTime.toDate ? e.actualTime.toDate() : e.actualTime);
      const hour = date.getHours();
      hourCounts[hour] = (hourCounts[hour] || 0) + 1;
    });

    const mostFrequentHour = Object.entries(hourCounts).sort((a, b) => b[1] - a[1])[0]?.[0];
    if (mostFrequentHour === undefined) continue;

    const currentTime = new Date();
    const updatedTime = new Date(currentTime);
    updatedTime.setHours(mostFrequentHour, 0, 0, 0);

    try {
      await db.collection("reminders").doc(reminderId).update({
        time: updatedTime.toISOString()
      });
      console.log(`✅ Updated reminder ${reminderId} to ${updatedTime.toISOString()}`);
    } catch (err) {
      console.error(`❌ Failed to update reminder ${reminderId}`, err.message);
    }
  }

  console.log("🎯 Finished adjusting reminder times.");
});

//  Missed Reminder Checker
exports.checkMissedReminders = onSchedule("every 24 hours", async () => {
  console.log("🔍 Checking for missed reminders...");

  const now = new Date();
  const cutoff = new Date(now.getTime() - 24 * 60 * 60 * 1000);

  const remindersSnap = await db.collection("reminders").get();
  const notificationsSnap = await db.collection("notifications").get();

  const doneMap = new Map();
  notificationsSnap.forEach(doc => {
    const n = doc.data();
    const key = `${n.patientId}_${n.reminderName}_${n.reminderType}`;
    const completed = new Date(n.completedAt?.toDate ? n.completedAt.toDate() : n.completedAt);
    doneMap.set(key, completed);
  });

  for (const doc of remindersSnap.docs) {
    const r = doc.data();
    const key = `${r.patientId}_${r.name}_${r.type}`;
    const scheduled = new Date(r.time?.toDate ? r.time.toDate() : r.time);

    if (scheduled < cutoff && (!doneMap.has(key) || doneMap.get(key) < scheduled)) {
      try {
        await db.collection("notifications").add({
          patientId: r.patientId,
          reminderName: r.name,
          reminderType: r.type,
          status: "missed",
          completedAt: now,
        });
        console.log(`🚨 Reminder missed: ${r.name} (${r.type}) for patient ${r.patientId}`);
      } catch (err) {
        console.error("❌ Failed to log missed reminder", err.message);
      }
    }
  }

  console.log("✅ Finished checking missed reminders.");
});




// UPDATED index.js WITH PERSONALIZED AND HUMAN-LIKE CHATBOT ENHANCEMENTS
// (All core features retained)

// ... [No changes to imports, initialization, or getSignedUploadUrl, adjustReminderTimes, checkMissedReminders]

// ✅ Chatbot Entry
exports.chatbotReply = functions.https.onRequest(async (req, res) => {
  try {
    const text = (req.body.message || "").toLowerCase();
    const patientId = req.body.patientId;
    if (!text || !patientId) {
      return res.status(400).json({ reply: "Missing message or patient ID." });
    }

    console.log("📥 Input Message:", text);
    console.log("🧠 Patient ID:", patientId);

    let reply = "", tts = "";

    // 🧾 Get Patient Name
    let name = "";
    try {
      const patientDoc = await db.collection("patients").doc(patientId).get();
      if (patientDoc.exists) name = patientDoc.data().name || "";
    } catch (err) { console.error("⚠️ Error fetching name:", err); }

    // ✨ Friendly Phrases
    const greetings = [
      `👋 Hi ${name || "there"}, how can I assist you today?`,
      `🙂 Hello${name ? ", " + name : ""}! Need anything?`,
      `Hey there${name ? ", " + name : ""}! 👂 I'm listening.`
    ];
    const endings = [
      "Let me know if you need anything else 💬.",
      "I'm always here to help 🤗.",
      "Would you like to see a photo or hear a joke next?"
    ];
    const greeting = greetings[Math.floor(Math.random() * greetings.length)];
    const ending = endings[Math.floor(Math.random() * endings.length)];

    // 🎞️ MEMORY VAULT
    if (text.includes("memory") || text.includes("photo") || text.includes("picture")) {
      const snap = await db.collection(`patients/${patientId}/memoryVault`).orderBy("uploadedAt", "desc").limit(3).get();
      if (!snap.empty) {
        const urls = snap.docs.map(doc => doc.data().downloadUrl || doc.data().url || doc.data().imageUrl).filter(url => typeof url === "string" && url.startsWith("http"));
        if (urls.length > 0) {
          reply = "IMAGE:" + urls.join(" ");
          tts = `Here are some of your memory photos!`;
        } else {
          reply = `🖼️ I found some memory entries but couldn't load the images.`;
          tts = reply.replace(/🖼️/, "");
        }
      } else {
        reply = `😔 I couldn’t find any memory photos yet.`;
        tts = reply.replace(/😔/, "");
      }
    }

    // 💊 MEDICATIONS
    else if (text.includes("medication") || text.includes("medicine")) {
      const medsSnap = await db.collection("medications").where("patientId", "==", patientId).get();
      if (!medsSnap.empty) {
        const medNames = medsSnap.docs.map(doc => doc.data().name).filter(Boolean).join(", ");
        reply = `💊 You are currently taking: ${medNames}. ${ending}`;
        tts = `You are currently taking the following medications: ${medNames}.`;
      } else {
        reply = `💊 I couldn't find any medications listed right now.`;
        tts = reply.replace(/💊/, "");
      }
    }

    // ⏰ REMINDERS (Multiple Support)
    else if (text.includes("reminder") || text.includes("tasks")) {
      const snap = await db.collection("reminders")
        .where("patientId", "==", patientId)
        .orderBy("time", "asc")
        .limit(3)
        .get();

      if (!snap.empty) {
        const lines = snap.docs.map(doc => {
          const d = doc.data();
          const t = new Date(d.time);
          const fmt = t.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
          return `⏰ ${d.type} reminder: "${d.name}" at ${fmt}`;
        });
        reply = `${lines.join("\n")}. ${ending}`;
        tts = `Here are your next reminders. ` + lines.map(l => l.replace(/[^a-zA-Z0-9 ]/g, "")).join(". ");
      } else {
        reply = "📭 No reminders found at the moment.";
        tts = "I didn’t find any reminders right now.";
      }
    }

    // 📅 APPOINTMENTS
    else if (text.includes("appointment")) {
      const now = new Date();
      const snap = await db.collection("appointments")
        .where("patientId", "==", patientId)
        .orderBy("datetime", "asc")
        .limit(1)
        .get();
      if (!snap.empty) {
        const d = snap.docs[0].data();
        const t = new Date(d.dateTime);
        const fmt = t.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        reply = `📅 You have an appointment: "${d.title}" at ${fmt}. ${ending}`;
        tts = `You have an appointment: ${d.title} at ${fmt}.`;
      } else {
        reply = "📭 No upcoming appointments found.";
        tts = "I didn’t find any upcoming appointments.";
      }
    }

    // 🫶 EMOTION SUPPORT
    else if (text.includes("sad") || text.includes("lonely") || text.includes("bored")) {
      reply = `❤️ I'm right here with you${name ? ", " + name : ""}. Would a photo or joke cheer you up?`;
      tts = reply.replace(/❤️/, "");
    }

    // 😄 JOKES
    else if (text.includes("joke") || text.includes("funny")) {
      const jokes = [
        "Why did the tomato blush? Because it saw the salad dressing! 😄",
        "Why don’t skeletons fight each other? They don’t have the guts! 💀",
        "What did one wall say to the other? I'll meet you at the corner! 😆"
      ];
      reply = jokes[Math.floor(Math.random() * jokes.length)];
      tts = reply.replace(/[^a-zA-Z0-9 ]/g, "");
    }

    // 🤷‍♀️ FALLBACK
    else {
      const fallbacks = [
        `🤔 Hmm, I'm not sure about that. Try asking about your photos, medicines, or appointments.`,
        `🧠 I didn’t catch that. Maybe try “Do I have any reminders?”`,
        `📣 I’m still learning! Want to hear a joke or see your memory photos?`
      ];
      reply = fallbacks[Math.floor(Math.random() * fallbacks.length)];
      tts = reply.replace(/[^a-zA-Z0-9 ]/g, "");
    }

    // 🧠 Save Chat Memory
    await db.collection(`patients/${patientId}/chatMemory`).add({
      userMessage: text,
      botReply: reply,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("🤖 Bot Reply:", reply);
    return res.json({ reply, tts });
  } catch (err) {
    console.error("❌ chatbotReply error:", err);
    return res.status(500).json({ reply: "Oops! Something went wrong.", tts: "Something went wrong." });
  }
});


