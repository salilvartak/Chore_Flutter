import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import {setGlobalOptions} from "firebase-functions/v2"; 
import * as admin from "firebase-admin";

admin.initializeApp();
setGlobalOptions({ region: "asia-south1" });

export const notifyOnNewChore = onDocumentCreated(
  "families/{familyId}/chores/{choreId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const chore = snap.data();
    const assigneeId = chore.assignedTo;
    const creatorId = chore.createdBy;

    if (creatorId === assigneeId) return;

    const userDoc = await admin.firestore().collection("users").doc(assigneeId).get();
    const token = userDoc.data()?.fcmToken;

    if (!token) return;

    const message = {
      notification: {
        title: "New Chore Assigned! 🧹",
        body: `You have been assigned: ${chore.title}`,
      },
      token: token,
    };

    await admin.messaging().send(message);
  }
);

export const notifyOnChoreCompleted = onDocumentUpdated(
  "families/{familyId}/chores/{choreId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const before = snap.before.data();
    const after = snap.after.data();

    if (after.isCompleted === true && before.isCompleted === false) {
      const creatorId = after.createdBy;
      const assigneeId = after.assignedTo;

      if (creatorId === assigneeId) return;

      const userDoc = await admin.firestore().collection("users").doc(creatorId).get();
      const token = userDoc.data()?.fcmToken;

      if (!token) return;

      const assigneeName = after.assignedToName || "Someone";
      const message = {
        notification: {
          title: "Chore Completed! 🎉",
          body: `${assigneeName} just completed: ${after.title}`,
        },
        token: token,
      };

      await admin.messaging().send(message);
    }
  }
);