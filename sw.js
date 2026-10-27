// MeetMind AI - Service Worker
const CACHE_NAME = 'meetmind-ai-cache-v2';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './app.html',
  './login.html',
  './privacy.html',
  './terms.html',
  './style.css',
  './app.js',
  './firebase-service.js',
  './manifest.json',
  './assets/orb.jpg',
  './assets/emily.jpg',
  './assets/icon-192.png',
  './assets/icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE);
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }
      return fetch(event.request).catch(() => {
        return caches.match('./index.html');
      });
    })
  );
});

