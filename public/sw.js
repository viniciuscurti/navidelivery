// Service Worker para PWA - cache básico e atualização
const CACHE_NAME = 'navidelivery-cache-v1';
const urlsToCache = [
  '/',
  '/favicon.ico',
  '/apple-touch-icon.png',
  '/manifest.json'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => {
      return Promise.all(
        keys.filter(key => key !== CACHE_NAME)
            .map(key => caches.delete(key))
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  // Estratégia cache-first simples
  event.respondWith(
    caches.match(event.request).then(response => response || fetch(event.request))
  );
});
