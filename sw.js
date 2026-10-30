// MeetMind AI - Service Worker
const CACHE_NAME = 'meetmind-ai-cache-v6';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './app.html',
  './login.html',
  './privacy.html',
  './terms.html',
  '/privacy',
  '/terms',
  '/app',
  '/login',
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
      return cache.addAll(ASSETS_TO_CACHE).catch((err) => {
        console.warn('SW cache.addAll notice:', err);
      });
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
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }
      return fetch(event.request).catch(async () => {
        if (event.request.mode === 'navigate') {
          if (url.pathname.includes('privacy')) {
            return (await caches.match('./privacy.html')) || (await caches.match('/privacy'));
          }
          if (url.pathname.includes('terms')) {
            return (await caches.match('./terms.html')) || (await caches.match('/terms'));
          }
          if (url.pathname.includes('app')) {
            return (await caches.match('./app.html')) || (await caches.match('/app'));
          }
          if (url.pathname.includes('login') || url.pathname.includes('signup')) {
            return (await caches.match('./login.html')) || (await caches.match('/login'));
          }
          return caches.match('./index.html');
        }
        return new Response('Network offline', { status: 503, headers: { 'Content-Type': 'text/plain' } });
      });
    })
  );
});

