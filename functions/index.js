/* eslint-disable max-len, require-jsdoc */
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Trigger when a follower doc is created
exports.onFollowerCreate = functions.firestore
    .document("users/{targetUid}/followers/{followerUid}")
    .onCreate(async (snap, context) => {
      const {targetUid, followerUid} = context.params;
      const targetRef = db.collection("users").doc(targetUid);
      const followerRef = db.collection("users").doc(followerUid);

      try {
        return db.runTransaction(async (t) => {
          t.update(targetRef, {
            followersCount: admin.firestore.FieldValue.increment(1),
          });
          t.update(followerRef, {
            followingCount: admin.firestore.FieldValue.increment(1),
          });
        });
      } catch (error) {
        console.error("Error in onFollowerCreate:", error);
        throw error;
      }
    });

// Trigger when a follower doc is deleted
exports.onFollowerDelete = functions.firestore
    .document("users/{targetUid}/followers/{followerUid}")
    .onDelete(async (snap, context) => {
      const {targetUid, followerUid} = context.params;
      const targetRef = db.collection("users").doc(targetUid);
      const followerRef = db.collection("users").doc(followerUid);

      try {
        return db.runTransaction(async (t) => {
          t.update(targetRef, {
            followersCount: admin.firestore.FieldValue.increment(-1),
          });
          t.update(followerRef, {
            followingCount: admin.firestore.FieldValue.increment(-1),
          });
        });
      } catch (error) {
        console.error("Error in onFollowerDelete:", error);
        throw error;
      }
    });

function createNotificationDoc({userId, title, body, type, orderId, dedupeKey}) {
  return {
    userId,
    title,
    body,
    type,
    orderId: orderId || null,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    dedupeKey: dedupeKey || null,
  };
}

async function createNotificationIfMissing(payload) {
  if (!payload.userId) return;

  if (payload.dedupeKey) {
    const existing = await db
        .collection("notifications")
        .where("dedupeKey", "==", payload.dedupeKey)
        .limit(1)
        .get();
    if (!existing.empty) return;
  }

  await db.collection("notifications").add(payload);
}

function toDateMaybe(value) {
  if (!value) return null;
  if (value.toDate) return value.toDate();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function normalizeName(data, fallback) {
  if (!data) return fallback;
  const preferred = [
    data.fullName,
    data.name,
    data.username,
    data.firstName,
    data.displayName,
  ];
  for (const candidate of preferred) {
    const value = (candidate || "").toString().trim();
    if (value) return value;
  }
  return fallback;
}

function deterministicDirectChatId(uidA, uidB) {
  const ids = [uidA, uidB].map((v) => (v || "").toString()).sort();
  return `${ids[0]}_${ids[1]}`;
}

exports.onCustomOrderCreateSyncAndNotify = functions.firestore
    .document("custom_orders/{orderId}")
    .onCreate(async (snap, context) => {
      const data = snap.data() || {};
      const orderId = context.params.orderId;
      const clientUserId = (data.clientUserId || "").toString();
      const tailorId = (data.tailorId || "").toString();
      const style = (data.style || "Order").toString();
      const clientName = (data.clientName || "Client").toString();

      const writes = [];

      // Mirror order to client-facing subcollection for easy synchronization.
      if (clientUserId) {
        writes.push(
            db
                .collection("users")
                .doc(clientUserId)
                .collection("incoming_orders")
                .doc(orderId)
                .set({
                  orderId,
                  tailorId,
                  clientUserId,
                  clientName,
                  style,
                  status: (data.status || "active").toString(),
                  dueDate: data.dueDate || null,
                  createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
                  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                }, {merge: true}),
        );
      }

      // Tailor notification
      if (tailorId) {
        writes.push(
            createNotificationIfMissing(
                createNotificationDoc({
                  userId: tailorId,
                  title: "New Order Created",
                  body: `${clientName} placed a new order for ${style}.`,
                  type: "orderCreated",
                  orderId,
                  dedupeKey: `order_created_tailor_${orderId}_${tailorId}`,
                }),
            ),
        );
      }

      // Client notification (only when linked user exists)
      if (clientUserId) {
        writes.push(
            createNotificationIfMissing(
                createNotificationDoc({
                  userId: clientUserId,
                  title: "Order Assigned",
                  body: `Your ${style} order has been created by your tailor.`,
                  type: "orderCreated",
                  orderId,
                  dedupeKey: `order_created_client_${orderId}_${clientUserId}`,
                }),
            ),
        );
      }

      await Promise.all(writes);
      return null;
    });

exports.onCustomOrderUpdateSyncClient = functions.firestore
    .document("custom_orders/{orderId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data() || {};
      const after = change.after.data() || {};
      const orderId = context.params.orderId;

      const beforeClientUserId = (before.clientUserId || "").toString();
      const afterClientUserId = (after.clientUserId || "").toString();

      if (beforeClientUserId && beforeClientUserId !== afterClientUserId) {
        await db
            .collection("users")
            .doc(beforeClientUserId)
            .collection("incoming_orders")
            .doc(orderId)
            .delete()
            .catch(() => null);
      }

      if (!afterClientUserId) {
        return null;
      }

      await db
          .collection("users")
          .doc(afterClientUserId)
          .collection("incoming_orders")
          .doc(orderId)
          .set({
            orderId,
            tailorId: (after.tailorId || "").toString(),
            clientUserId: afterClientUserId,
            clientName: (after.clientName || "Client").toString(),
            style: (after.style || "Order").toString(),
            status: (after.status || "active").toString(),
            dueDate: after.dueDate || null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});

      return null;
    });

exports.onCustomOrderDeleteSyncClient = functions.firestore
    .document("custom_orders/{orderId}")
    .onDelete(async (snap, context) => {
      const data = snap.data() || {};
      const clientUserId = (data.clientUserId || "").toString();
      const orderId = context.params.orderId;

      if (!clientUserId) return null;

      await db
          .collection("users")
          .doc(clientUserId)
          .collection("incoming_orders")
          .doc(orderId)
          .delete()
          .catch(() => null);

      return null;
    });

exports.notifyCustomOrderDeadlines = functions.pubsub
    .schedule("every 24 hours")
    .onRun(async () => {
      const snapshot = await db
          .collection("custom_orders")
          .where("status", "==", "active")
          .limit(500)
          .get();

      const now = new Date();
      const msPerDay = 24 * 60 * 60 * 1000;
      const jobs = [];

      for (const doc of snapshot.docs) {
        const data = doc.data() || {};
        const orderId = doc.id;
        const dueDate = toDateMaybe(data.dueDate);
        if (!dueDate) continue;

        const daysRemaining = Math.ceil((dueDate.getTime() - now.getTime()) / msPerDay);
        if (daysRemaining < 0 || daysRemaining > 3) continue;

        const style = (data.style || "Order").toString();
        const clientName = (data.clientName || "Client").toString();
        const tailorId = (data.tailorId || "").toString();
        const clientUserId = (data.clientUserId || "").toString();

        const suffix = daysRemaining === 0 ? "today" : `in ${daysRemaining} day${daysRemaining > 1 ? "s" : ""}`;

        if (tailorId) {
          jobs.push(
              createNotificationIfMissing(
                  createNotificationDoc({
                    userId: tailorId,
                    title: "Deadline Approaching",
                    body: `${clientName}'s ${style} is due ${suffix}.`,
                    type: "deadlineReminder",
                    orderId,
                    dedupeKey: `deadline_tailor_${orderId}_${tailorId}_${daysRemaining}`,
                  }),
              ),
          );
        }

        if (clientUserId) {
          jobs.push(
              createNotificationIfMissing(
                  createNotificationDoc({
                    userId: clientUserId,
                    title: "Order Deadline Update",
                    body: `Your ${style} is due ${suffix}.`,
                    type: "deadlineReminder",
                    orderId,
                    dedupeKey: `deadline_client_${orderId}_${clientUserId}_${daysRemaining}`,
                  }),
              ),
          );
        }
      }

      await Promise.all(jobs);
      return null;
    });

exports.onGroupOrderFilledCreateTailorOrder = functions.firestore
    .document("group_orders/{groupId}")
    .onUpdate(async (change, context) => {
      const groupId = context.params.groupId;
      const after = change.after.data() || {};

      const maxParticipants = Number(after.maxParticipants || 0);
      const members = Array.isArray(after.members) ? after.members : [];
      const isFull =
      ((after.status || "").toString().toLowerCase() === "full") ||
      (maxParticipants > 0 && members.length >= maxParticipants);

      if (!isFull || !after.professionalId) {
        return null;
      }

      const groupRef = db.collection("group_orders").doc(groupId);
      const created = await db.runTransaction(async (t) => {
        const groupSnap = await t.get(groupRef);
        const latest = groupSnap.data() || {};
        if (latest.tailorOrderId) {
          return null;
        }

        const latestMax = Number(latest.maxParticipants || 0);
        const latestMembers = Array.isArray(latest.members) ? latest.members : [];
        const latestIsFull =
        ((latest.status || "").toString().toLowerCase() === "full") ||
        (latestMax > 0 && latestMembers.length >= latestMax);

        if (!latestIsFull) {
          return null;
        }

        const now = new Date();
        const deadline = toDateMaybe(latest.deadline);
        const suggestedDueDate = deadline && deadline > now ?
        new Date(deadline.getTime() + 14 * 24 * 60 * 60 * 1000) :
        new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);
        const daysToDeliver = Math.max(
            3,
            Math.ceil((suggestedDueDate.getTime() - now.getTime()) / (24 * 60 * 60 * 1000)),
        );

        const type = (latest.type || "sewing").toString();
        const typeLabel = type === "fabric" ? "Fabric" : "Sewing";
        const groupName = (latest.name || "Group Order").toString();
        const professionalId = (latest.professionalId || "").toString();
        const professionalName = (latest.professionalName || "Professional").toString();

        const memberNames = latestMembers
            .map((m) => (m && m.userName ? m.userName : "Member").toString())
            .filter(Boolean);
        const clientName = `Group: ${groupName}`;
        const style = `${typeLabel} Group Order`;
        const measurements = JSON.stringify({
          groupOrderId: groupId,
          groupName,
          type,
          professionalId,
          professionalName,
          members: latestMembers.map((m) => ({
            userId: (m.userId || "").toString(),
            userName: (m.userName || "Member").toString(),
            orderDescription: (m.orderDescription || "").toString(),
            basePrice: m.basePrice != null ? m.basePrice : null,
          })),
        });

        const pricedMembers = latestMembers
            .map((m) => Number(m.basePrice || 0))
            .filter((value) => Number.isFinite(value) && value > 0);
        const basePrice = pricedMembers.length ?
        Math.round(pricedMembers.reduce((a, b) => a + b, 0)) :
        0;

        const orderRef = db.collection("custom_orders").doc();
        t.set(orderRef, {
          tailorId: professionalId,
          clientName,
          clientUserId: null,
          style,
          styleImageUrl: latest.image || null,
          basePrice,
          measurements,
          daysToDeliver,
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          dueDate: admin.firestore.Timestamp.fromDate(suggestedDueDate),
          source: "group_order_auto",
          groupOrderId: groupId,
          groupName,
          groupType: type,
          memberCount: latestMembers.length,
          memberNames,
        });

        t.update(groupRef, {
          status: "inProgress",
          tailorOrderId: orderRef.id,
          tailorOrderCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {
          orderId: orderRef.id,
          groupName,
          typeLabel,
          professionalId,
          professionalName,
          members: latestMembers,
        };
      });

      if (!created) {
        return null;
      }

      const {orderId, groupName, typeLabel, professionalId, professionalName} = created;
      const membersForChat = Array.isArray(created.members) ? created.members : [];

      const userIds = [...new Set(membersForChat
          .map((m) => (m.userId || "").toString())
          .filter((id) => id && id !== professionalId))];

      const userProfiles = await Promise.all(
          userIds.map(async (uid) => {
            const snap = await db.collection("users").doc(uid).get();
            const data = snap.exists ? (snap.data() || {}) : {};
            return {
              uid,
              name: normalizeName(data, "User"),
            };
          }),
      );

      const memberNameById = new Map(
          membersForChat.map((m) => [
            (m.userId || "").toString(),
            (m.userName || "Member").toString(),
          ]),
      );

      const batch = db.batch();
      for (const profile of userProfiles) {
        const chatId = deterministicDirectChatId(professionalId, profile.uid);
        const chatRef = db.collection("chats").doc(chatId);
        batch.set(chatRef, {
          participants: [professionalId, profile.uid],
          participantNames: {
            [professionalId]: professionalName,
            [profile.uid]: memberNameById.get(profile.uid) || profile.name,
          },
          requestStatus: "accepted",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastMessage: `Group ${groupName} is now full. Order #${orderId} was created.`,
        }, {merge: true});

        const systemMessageRef = chatRef
            .collection("messages")
            .doc(`group_full_${groupId}`);
        batch.set(systemMessageRef, {
          senderId: "system",
          text: `Group ${groupName} is now full. Your tailor has received the order (${typeLabel}).`,
          type: "group_order_created",
          orderId,
          groupOrderId: groupId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      }

      const groupMessageRef = groupRef
          .collection("messages")
          .doc(`group_full_${groupId}`);
      batch.set(groupMessageRef, {
        senderId: "system",
        senderName: "System",
        senderImage: "",
        message: `Group is full. Tailor order #${orderId} has been created and private chats are ready.`,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        isSystemMessage: true,
      }, {merge: true});

      await batch.commit();

      await Promise.all([
        createNotificationIfMissing(
            createNotificationDoc({
              userId: professionalId,
              title: "Group Order Ready",
              body: `${groupName} is full. Order #${orderId} has been created.`,
              type: "groupOrderReady",
              orderId,
              dedupeKey: `group_ready_tailor_${groupId}_${professionalId}`,
            }),
        ),
        ...userProfiles.map((profile) =>
          createNotificationIfMissing(
              createNotificationDoc({
                userId: profile.uid,
                title: "Group Filled",
                body: `${groupName} is now full. Your tailor has started processing the order.`,
                type: "groupOrderReady",
                orderId,
                dedupeKey: `group_ready_member_${groupId}_${profile.uid}`,
              }),
          ),
        ),
      ]);

      return null;
    });

