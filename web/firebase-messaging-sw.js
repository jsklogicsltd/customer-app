// Import and configure the Firebase SDK
// These scripts are made available when the app is served locally or on Firebase Hosting
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyBAOKei960WvE77flTuRE6nWnbuZnjcGGY",
  appId: "1:926512925301:web:d7c5fc1353895e6b0c863c",
  messagingSenderId: "926512925301",
  projectId: "karsaazi-cf8a4",
});

const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
