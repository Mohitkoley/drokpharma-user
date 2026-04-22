importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyA9mzewWYWCGXJFjSR4xdZeN-s0NU4ucOg",
    authDomain: "drokpharma.firebaseapp.com",
    projectId: "drokpharma",
    storageBucket: "drokpharma.firebasestorage.app",
    messagingSenderId: "789606222810",
    appId: "1:789606222810:web:e894da7ec18071e8520ee3",
    measurementId: "G-8XD5GYXKKC"
});

const messaging = firebase.messaging();

messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            const title = payload.notification.title;
            const options = {
                body: payload.notification.score
              };
            return registration.showNotification(title, options);
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});