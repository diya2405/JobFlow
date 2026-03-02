const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document("notifications/{id}") // your Firestore path
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userId = data.userId;

    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) return;

    const payload = {
      notification: {
        title: data.title || "New Alert",
        body: data.body || "You have a new message",
        sound: "default",
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        screen: data.screen || "HomePage",
      },
    };

    await admin.messaging().sendToDevice(fcmToken, payload);
  });
