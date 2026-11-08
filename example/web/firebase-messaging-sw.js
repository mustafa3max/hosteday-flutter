importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

// 1. Force immediate update and takeover
self.addEventListener('install', function (event) {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

// 2. Synchronous Firebase initialization (Prevents push event drop race condition)
const firebaseConfig = {
  apiKey: "AIzaSy_YOUR_DUMMY_WEB_API_KEY_HERE",
  authDomain: "example-app.firebaseapp.com",
  projectId: "example-firebase-project",
  storageBucket: "example-firebase-project.firebasestorage.app",
  messagingSenderId: "000000000000",
  appId: "1:000000000000:web:0000000000000000000000"
};

let messaging = null;
try {
  if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
  }
  messaging = firebase.messaging();
} catch (e) {
  console.error('[firebase-messaging-sw.js] Firebase sync init error:', e);
}

// 3. Central notification display function
function showNotificationFromPayload(payload) {
  if (!payload) return Promise.resolve();

  const notif = payload.notification || {};
  const data = payload.data || {};

  const title = notif.title || data.title || 'HosteDay Notification';
  const body = notif.body || data.body || data.message || '';

  // Use a unique or consistent tag to prevent duplicate popups if both listeners catch it
  const notifId = data.id || data.tag || payload.fcmMessageId || payload.message_id || ('hosteday_' + Date.now());

  const notificationOptions = {
    body: body,
    icon: notif.icon || data.icon || '/icons/Icon-192.png',
    badge: '/favicon.png',
    tag: String(notifId),
    data: data,
    requireInteraction: true,
  };

  // Broadcast to open browser tabs so Flutter app updates its UI/inbox live
  self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
    clientList.forEach(function (client) {
      client.postMessage({
        type: 'HOSTEDAY_PUSH_NOTIFICATION',
        title: title,
        body: body,
        payload: payload,
      });
    });
  });

  return self.registration.showNotification(title, notificationOptions);
}

// 4. Firebase Background message handler
if (messaging) {
  messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] onBackgroundMessage received:', payload);
    return showNotificationFromPayload(payload);
  });
}

// 5. Fallback push listener for raw Web Push frames
self.addEventListener('push', function (event) {
  console.log('[firebase-messaging-sw.js] Push event received:', event);

  let payload = {};
  if (event.data) {
    try {
      payload = event.data.json();
    } catch (e) {
      try {
        payload = {
          notification: {
            title: 'HosteDay Notification',
            body: event.data.text(),
          }
        };
      } catch (_) {}
    }
  }

  // Ensure notification is displayed and the browser does not kill the event
  event.waitUntil(showNotificationFromPayload(payload));
});

// 6. Handle notification click
self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
