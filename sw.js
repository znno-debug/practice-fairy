// 연습요정 (Practice Fairy) Service Worker - v12.0.0 (카카오톡 공유 카드 상세보기 버튼 & 가로형 썸네일 & 리포트 직행 연결)
const CACHE_NAME = 'fairy-cache-v12';
const STATIC_ASSETS = [
  './',
  './index.html',
  './share.html',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-maskable-192.png',
  './icons/icon-maskable-512.png',
  './icons/apple-touch-icon.png',
  './icons/favicon.png',
  './icons/icon.svg'
];

// Install: Cache static resources
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS);
    }).then(() => self.skipWaiting())
  );
});

// Activate: Clean up old caches
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

// Fetch: Network first with offline fallback for HTML, Cache-first for static icons
self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);

  // Ignore non-GET requests and external URLs like youtube or tailwind cdn
  if (req.method !== 'GET' || !url.origin.includes(self.location.origin)) {
    return;
  }

  // Static icons: Cache-first
  if (url.pathname.includes('/icons/')) {
    event.respondWith(
      caches.match(req).then((cached) => {
        return cached || fetch(req).then((networkRes) => {
          return caches.open(CACHE_NAME).then((cache) => {
            cache.put(req, networkRes.clone());
            return networkRes;
          });
        });
      })
    );
    return;
  }

  // HTML / App navigation: Network-first, fallback to cache
  event.respondWith(
    fetch(req)
      .then((networkRes) => {
        if (networkRes && networkRes.status === 200) {
          const resClone = networkRes.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, resClone));
        }
        return networkRes;
      })
      .catch(() => {
        return caches.match(req).then((cached) => {
          if (cached) return cached;
          if (req.mode === 'navigate') {
            return caches.match('./index.html');
          }
        });
      })
  );
});
