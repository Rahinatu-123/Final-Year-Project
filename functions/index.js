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

async function deleteSecureShareArtifacts(shareId, shareData) {
  const batch = db.batch();
  const shareRef = db.collection('secure_image_shares').doc(shareId);

  // For Cloudinary images, we skip file deletion since they're managed externally.
  // You can optionally call Cloudinary API to delete the image if needed.
  // const publicId = shareData.cloudinaryPublicId;
  // if (publicId) {
  //   // Call Cloudinary destroy API with your credentials
  //   // await cloudinary.uploader.destroy(publicId);
  // }

  batch.update(shareRef, {
    status: 'deleted',
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    secureImageUrl: admin.firestore.FieldValue.delete(),
  });

  const chatId = shareData.chatId;
  if (chatId) {
    const secureMessages = await db
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .where('secureShareId', '==', shareId)
      .get();

    secureMessages.forEach((doc) => {
      batch.update(doc.ref, {
        secureDeleted: true,
        secureImageUrl: admin.firestore.FieldValue.delete(),
      });
    });
  }

  await batch.commit();
}

exports.onShopOrderCompletedCleanupSecureImages = functions.firestore
  .document('shop_orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    if (before.status === 'completed' || after.status !== 'completed') {
      return null;
    }

    const { orderId } = context.params;
    const sharesSnap = await db
      .collection('secure_image_shares')
      .where('orderId', '==', orderId)
      .where('status', 'in', ['active', 'expired'])
      .get();

    for (const doc of sharesSnap.docs) {
      await deleteSecureShareArtifacts(doc.id, doc.data());
    }

    return null;
  });

exports.cleanupExpiredSecureImages = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async () => {
    const now = new Date();
    const sharesSnap = await db
      .collection('secure_image_shares')
      .where('status', '==', 'active')
      .limit(300)
      .get();

    for (const doc of sharesSnap.docs) {
      const data = doc.data();
      const expiresAt = data.expiresAt && data.expiresAt.toDate
        ? data.expiresAt.toDate()
        : null;

      if (expiresAt && expiresAt <= now) {
        await deleteSecureShareArtifacts(doc.id, data);
      }
    }

    return null;
  });