const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Trigger when a follower doc is created
exports.onFollowerCreate = functions.firestore
  .document('users/{targetUid}/followers/{followerUid}')
  .onCreate(async (snap, context) => {
    const { targetUid, followerUid } = context.params;
    const targetRef = db.collection('users').doc(targetUid);
    const followerRef = db.collection('users').doc(followerUid);

    try {
      return db.runTransaction(async (t) => {
        t.update(targetRef, {
          followersCount: admin.firestore.FieldValue.increment(1)
        });
        t.update(followerRef, {
          followingCount: admin.firestore.FieldValue.increment(1)
        });
      });
    } catch (error) {
      console.error('Error in onFollowerCreate:', error);
      throw error;
    }
  });

// Trigger when a follower doc is deleted
exports.onFollowerDelete = functions.firestore
  .document('users/{targetUid}/followers/{followerUid}')
  .onDelete(async (snap, context) => {
    const { targetUid, followerUid } = context.params;
    const targetRef = db.collection('users').doc(targetUid);
    const followerRef = db.collection('users').doc(followerUid);

    try {
      return db.runTransaction(async (t) => {
        t.update(targetRef, {
          followersCount: admin.firestore.FieldValue.increment(-1)
        });
        t.update(followerRef, {
          followingCount: admin.firestore.FieldValue.increment(-1)
        });
      });
    } catch (error) {
      console.error('Error in onFollowerDelete:', error);
      throw error;
    }
  });