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
