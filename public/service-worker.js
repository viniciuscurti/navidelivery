const CACHE_NAME = 'navidelivery-cache-v1';
const OFFLINE_URLS = [
  '/',
  '/manifest.webmanifest'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(OFFLINE_URLS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
// Versão do cache principal
const CACHE_NAME = 'navidelivery-pwa-v2';
const OFFLINE_URL = '/offline.html';

// Pré-cache básico (páginas estáticas e manifest)
const PRECACHE_URLS = [
  '/',
  OFFLINE_URL,
  '/manifest.webmanifest'
];

// Cache dedicado para tiles de mapa com quota
const TILES_CACHE = 'tiles-cache-v1';
const MAX_TILES_ENTRIES = 400;

// Background Sync: DB e loja
const BG_DB_NAME = 'navidelivery-bg';
const BG_STORE = 'requests';
const BG_SYNC_TAG = 'sync-pings';

// Utils: limpar caches antigos
async function cleanupOldCaches() {
  const keys = await caches.keys();
  await Promise.all(
    keys
      .filter((key) => key !== CACHE_NAME && key !== TILES_CACHE)
      .map((key) => caches.delete(key))
  );
}

// Utils: limitar quantidade de entradas no cache de tiles
async function trimCache(cacheName, maxEntries) {
  const cache = await caches.open(cacheName);
  const keys = await cache.keys();
  if (keys.length > maxEntries) {
    const toDelete = keys.length - maxEntries;
    for (let i = 0; i < toDelete; i++) {
      await cache.delete(keys[i]);
    }
  }
}

// IndexedDB helpers para fila de BG Sync
function idbOpen() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(BG_DB_NAME, 1);
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains(BG_STORE)) {
        const store = db.createObjectStore(BG_STORE, { keyPath: 'id', autoIncrement: true });
        store.createIndex('created_at', 'created_at');
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function queueRequest(data) {
  const db = await idbOpen();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(BG_STORE, 'readwrite');
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
    const store = tx.objectStore(BG_STORE);
    store.add({ ...data, created_at: Date.now() });
  });
}

async function dequeueAll() {
  const db = await idbOpen();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(BG_STORE, 'readwrite');
    const store = tx.objectStore(BG_STORE);
    const items = [];
    store.openCursor().onsuccess = (event) => {
      const cursor = event.target.result;
      if (cursor) {
        items.push({ id: cursor.key, ...cursor.value });
        cursor.continue();
      } else {
        resolve({ db, tx, store, items });
      }
    };
    tx.onerror = () => reject(tx.error);
  });
}

async function deleteById(id) {
  const db = await idbOpen();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(BG_STORE, 'readwrite');
    const store = tx.objectStore(BG_STORE);
    store.delete(id).onsuccess = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
}

// Detecta se é uma URL de tile OSM
function isOsmTile(urlObj) {
  const host = urlObj.host;
  return /(^|\.)tile\.openstreetmap\.org$/.test(host);
}

// Install: pre-cache básico
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS))
  );
  self.skipWaiting();
});

// Activate: cleanup + claim
self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      await cleanupOldCaches();
      await self.clients.claim();
    })()
  );
});

// Fetch: estratégias por tipo, BG Sync para pings, e cache de tiles
self.addEventListener('fetch', (event) => {
  const { request } = event;

  // Background Sync: intercepta POSTs de pings para fila offline
  if (request.method === 'POST') {
    const url = new URL(request.url);

    // Enfileira apenas pings da API
    const isPing = url.pathname.match(/\/api\/.*\/pings$/);
    if (isPing) {
      event.respondWith(
        (async () => {
          try {
            // Tenta rede normalmente
            const response = await fetch(request.clone());
            return response;
          } catch (err) {
            // Em caso de falha, extrai corpo e cabeçalhos para fila
            let bodyText = '';
            try { bodyText = await request.clone().text(); } catch (_) {}
            const headers = {};
            for (const [k, v] of request.headers.entries()) headers[k] = v;

            await queueRequest({
              url: request.url,
              method: request.method,
              headers,
              body: bodyText
            });

            // Agenda sync
            if ('sync' in self.registration) {
              try { await self.registration.sync.register(BG_SYNC_TAG); } catch (_) {}
            }

            // Retorna 202 Accepted simulando recebimento para não quebrar UX
            return new Response(null, { status: 202, statusText: 'Accepted (queued offline)' });
          }
        })()
      );
      return; // Não seguir para demais estratégias
    }
  }

  // Somente GET para demais estratégias
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  const isSameOrigin = url.origin === self.location.origin;

  // Navegação (HTML): Network First com fallback offline
  const isNavigation =
    request.mode === 'navigate' ||
    (request.headers.get('accept') || '').includes('text/html');

  if (isNavigation) {
    event.respondWith(
      (async () => {
        try {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 5000);
          const networkResponse = await fetch(request, { signal: controller.signal });
          clearTimeout(timeoutId);

          const cache = await caches.open(CACHE_NAME);
          cache.put(request, networkResponse.clone());
          return networkResponse;
        } catch (err) {
          const cacheMatch = await caches.match(request);
          return cacheMatch || (await caches.match(OFFLINE_URL));
        }
      })()
    );
    return;
  }

  // Tiles OSM: Cache First com revalidação e quota
  if (isOsmTile(url)) {
    event.respondWith(
      (async () => {
        const cache = await caches.open(TILES_CACHE);
        const cached = await cache.match(request);
        if (cached) {
          // Atualiza em background
          fetch(request).then((resp) => {
            if (resp && resp.status === 200) {
              cache.put(request, resp.clone()).then(() => trimCache(TILES_CACHE, MAX_TILES_ENTRIES));
            }
          }).catch(() => {});
          return cached;
        } else {
          try {
            const resp = await fetch(request);
            if (resp && resp.status === 200) {
              await cache.put(request, resp.clone());
              await trimCache(TILES_CACHE, MAX_TILES_ENTRIES);
            }
            return resp;
          } catch (err) {
            // Sem tile e sem rede: tenta cache geral
            return caches.match(request);
          }
        }
      })()
    );
    return;
  }

  // Mesma origem (assets): Stale-While-Revalidate
  if (isSameOrigin) {
    event.respondWith(
      (async () => {
        const cache = await caches.open(CACHE_NAME);
        const cached = await cache.match(request);

        const fetchPromise = fetch(request)
          .then((networkResponse) => {
            if (
              networkResponse &&
              networkResponse.status === 200 &&
              (request.destination === 'script' ||
                request.destination === 'style' ||
                request.destination === 'image' ||
                request.destination === 'font')
            ) {
              cache.put(request, networkResponse.clone());
            }
            return networkResponse;
          })
          .catch(() => undefined);

        return cached || fetchPromise || (await caches.match(OFFLINE_URL));
      })()
    );
    return;
  }

  // Terceiros genéricos: rede com fallback ao cache
  event.respondWith(fetch(request).catch(() => caches.match(request)));
});

// Background Sync: reenvia a fila quando a conectividade volta
self.addEventListener('sync', (event) => {
  if (event.tag === BG_SYNC_TAG) {
    event.waitUntil(
      (async () => {
        try {
          const { items } = await dequeueAll();
          for (const item of items) {
            try {
              const headers = new Headers(item.headers || {});
              const resp = await fetch(item.url, {
                method: item.method || 'POST',
                headers,
                body: item.body || null
              });
              if (resp && (resp.ok || resp.status === 202 || resp.status === 204)) {
                await deleteById(item.id);
              }
            } catch (_) {
              // mantém na fila se falhar
            }
          }
        } catch (e) {
          // noop
        }
      })()
    );
  }
});
self.addEventListener('fetch', (event) => {
  const { request } = event;

  // Apenas GET
  if (request.method !== 'GET') return;

  event.respondWith(
    caches.match(request).then((cached) => {
      const fetchPromise = fetch(request)
        .then((networkResponse) => {
          // Cache apenas respostas 200 e do mesmo host
          if (
            networkResponse &&
            networkResponse.status === 200 &&
            new URL(request.url).origin === self.location.origin
          ) {
            const responseToCache = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, responseToCache));
          }
          return networkResponse;
        })
        .catch(() => cached);

      return cached || fetchPromise;
    })
  );
});
