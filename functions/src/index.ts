import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Trigger 1: When a new chore is created
export const notifyOnNewChore = onDocumentCreated(
  "families/{familyId}/chores/{choreId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const chore = snap.data();
    const assigneeId = chore.assignedTo;
    const creatorId = chore.createdBy;

    // Prevent sending a notification if the user assigned the chore to themselves
    if (creatorId === assigneeId) {
      return;
    }

    // Fetch the assignee's FCM token from the users collection
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(assigneeId)
      .get();
      
    const token = userDoc.data()?.fcmToken;

    if (!token) {
      console.log("No FCM token found for user:", assigneeId);
      return;
    }

    // Create the notification payload
    const message = {
      notification: {
        title: "New Chore Assigned! 🧹",
        body: `You have been assigned: ${chore.title}`,
      },
      token: token,
    };

    // Send the notification
    await admin.messaging().send(message);
  }
);

// Trigger 2: When a chore is updated (completed)
export const notifyOnChoreCompleted = onDocumentUpdated(
  "families/{familyId}/chores/{choreId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const before = snap.before.data();
    const after = snap.after.data();

    // Check if the status specifically changed from incomplete to complete
    if (after.isCompleted === true && before.isCompleted === false) {
      const creatorId = after.createdBy;
      const assigneeId = after.assignedTo;

      // Prevent sending if the user is completing their own self-assigned chore
      if (creatorId === assigneeId) {
        return;
      }

      // Fetch the creator's FCM token
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(creatorId)
        .get();
        
      const token = userDoc.data()?.fcmToken;

      if (!token) {
        console.log("No FCM token found for user:", creatorId);
        return;
      }

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