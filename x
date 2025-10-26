// Simple service worker for caching static assets and offline fallback
const CACHE = 'mj-static-v1';
const ASSETS = [
  '/', '/index.html', '/manifest.json',
  // Add other static assets you want cached (icons, fonts) e.g. '/assets/icon.png'
];

self.addEventListener('install', (e) => {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(ASSETS).catch(()=>{}))
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then(response => {
        // Optionally cache images and fonts
        const respClone = response.clone();
        const dest = event.request.destination;
        if (dest === 'image' || dest === 'font' || event.request.url.endsWith('.css') || event.request.url.endsWith('.js')) {
          caches.open(CACHE).then(cache => cache.put(event.request, respClone)).catch(()=>{});
        }
        return response;
      }).catch(() => {
        // Offline fallback for navigation
        if (event.request.mode === 'navigate') {
          return caches.match('/index.html');
        }
        return new Response('', { status: 503, statusText: 'Offline' });
      });
    })
  );
});
