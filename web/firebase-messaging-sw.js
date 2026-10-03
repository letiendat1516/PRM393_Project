// Firebase Cloud Messaging service worker (Flutter web).
// Config mirrors lib/firebase_options.dart (web app of project jobhub-prm393-g3).
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyChqirP28WRfHMAr86f7tgGL3pMnQR2bc0',
  appId: '1:718109953815:web:62f5e18d51a77a8097b152',
  messagingSenderId: '718109953815',
  projectId: 'jobhub-prm393-g3',
  authDomain: 'jobhub-prm393-g3.firebaseapp.com',
  storageBucket: 'jobhub-prm393-g3.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) || 'JobHub';
  const options = {
    body: (payload.notification && payload.notification.body) || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  };
  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  let url = '/';
  if (data.applicationId && data.type === 'APPLICATION_STATUS') url = '/applications/' + data.applicationId;
  else if (data.applicationId) url = '/employer/applications/' + data.applicationId;
  else if (data.type === 'JOB_APPROVED' || data.type === 'JOB_REJECTED') url = '/employer/jobs';
  event.waitUntil(clients.openWindow(url));
});
