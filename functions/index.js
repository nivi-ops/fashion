const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const TOPIC_MAP = {
  general: 'general_announcements',
  order: 'order_updates',
  promotion: 'promotions',
  class: 'class_reminders',
};

exports.sendNotificationOnCreate = onDocumentCreated(
  'notifications/{notifId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const title = data.title || "Sumathi's Style";
    const body = data.message || '';
    const type = data.type || 'general';
    const topic = TOPIC_MAP[type] || TOPIC_MAP.general;

    const message = {
      notification: { title, body },
      data: { type },
      topic,
    };

    try {
      const response = await getMessaging().send(message);
      await snap.ref.update({ push_sent: true, push_response: response });
      console.log(`Notification sent to topic "${topic}":`, response);
    } catch (error) {
      await snap.ref.update({ push_sent: false, push_error: `${error}` });
      console.error('Error sending notification:', error);
    }
  }
);

// ---------------------------------------------------------------------
// ADMIN ALERT — fires when a new order or contact form is submitted.
// Pushes to EVERY admin device token saved in `admin_tokens`
// (see NotificationService / admin_page.dart _saveAdminFcmToken()).
// This is what lets the admin get a push even with the app closed.
// ---------------------------------------------------------------------
async function pushToAdmins(title, body) {
  const db = require('firebase-admin/firestore').getFirestore();
  const tokensSnap = await db.collection('admin_tokens').get();
  const tokens = tokensSnap.docs.map((d) => d.id);
  if (tokens.length === 0) return null;

  return getMessaging().sendEachForMulticast({
    notification: { title, body },
    data: { type: 'admin_alert' },
    // 🔑 FIX: without this block, Android falls back to its own
    // default notification channel instead of the app's
    // "sumathi_admin_channel" — sound can be silent/unpredictable,
    // especially when the app is fully closed (terminated).
    android: {
      priority: 'high',
      notification: {
        channelId: 'sumathi_admin_channel', // must match admin_page.dart's channel id
        sound: 'default',
        priority: 'max',
      },
    },
    tokens,
  });
}

exports.notifyAdminOnNewOrder = onDocumentCreated(
  'orders/{orderId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const o = snap.data();
    const isCustom = (o.source || '').toLowerCase() === 'custom-order';
    await pushToAdmins(
      isCustom ? '✂️ New Customized Order' : '🛒 New Order Received',
      `${o.name || 'Customer'} — ${o.product || ''}`
    );
  }
);

exports.notifyAdminOnNewContact = onDocumentCreated(
  'contacts/{contactId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const c = snap.data();
    await pushToAdmins(
      '📨 New Contact Form Submission',
      `${c.name || 'Someone'} — ${c.service || c.message || ''}`
    );
  }
);

// ---------------------------------------------------------------------
// CUSTOMER ORDER STATUS UPDATE — fires when an order's `status` field
// changes (Ordered → Processing → Shipping → Delivered → Cancelled).
// Pushes to the `order_updates` topic customers are subscribed to
// (see NotificationService.syncTopicSubscriptions()).
// ---------------------------------------------------------------------
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');

exports.notifyCustomerOnStatusChange = onDocumentUpdated(
  'orders/{orderId}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === after.status) return null;

    return getMessaging().send({
      topic: TOPIC_MAP.order,
      notification: {
        title: '📦 Order Update',
        body: `Your order is now: ${after.status}`,
      },
      data: { type: 'order' },
    });
  }
);
