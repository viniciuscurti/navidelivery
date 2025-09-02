// Versão do cache
const CACHE_NAME = 'navidelivery-tracking-v1';

// Arquivos para armazenar em cache imediatamente
const STATIC_CACHE_URLS = [
  '/tracking/',
  '/tracking/index.html',
  '/tracking/styles.css',
  '/tracking/app.js',
  '/tracking/manifest.webmanifest',
  '/tracking/images/icon-192.png',
  '/tracking/images/icon-512.png',
  '/tracking/images/store-marker.svg',
  '/tracking/images/courier-marker.svg',
  '/tracking/images/destination-marker.svg',
  '/tracking/offline.html'
];

// Cache separado para tiles de mapa
const MAP_CACHE_NAME = 'navidelivery-map-tiles-v1';
// Limite de tiles para evitar usar
const MAX_MAP_TILES = 300;

// Instalação: cache inicial
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_CACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

// Ativação: limpeza de caches antigos
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.filter(cacheName => {
          return (cacheName !== CACHE_NAME && cacheName !== MAP_CACHE_NAME);
        }).map(cacheName => {
          return caches.delete(cacheName);
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Limita a quantidade de tiles de mapa em cache
async function limitMapTileCache() {
  const cache = await caches.open(MAP_CACHE_NAME);
  const keys = await cache.keys();

  if (keys.length > MAX_MAP_TILES) {
    // Remove os mais antigos primeiro (início da lista)
    const keysToDelete = keys.slice(0, keys.length - MAX_MAP_TILES);
    await Promise.all(keysToDelete.map(key => cache.delete(key)));
  }
}

// Interceptação de requisições
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Estratégia para tiles de mapa: Cache primeiro, depois rede
  if (url.href.includes('tile.openstreetmap.org') ||
      url.href.includes('api.maptiler.com')) {
    event.respondWith(handleMapTile(event.request));
    return;
  }

  // Estratégia para API: Rede com fallback para offline API response
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(handleApiRequest(event.request));
    return;
  }

  // Estratégia para assets estáticos: Cache primeiro, depois rede
  if (url.origin === self.location.origin) {
    event.respondWith(handleStaticAsset(event.request));
    return;
  }

  // Default: tenta rede, depois cache
  event.respondWith(
    fetch(event.request)
      .catch(() => caches.match(event.request))
  );
});

// Manipula tiles de mapa
async function handleMapTile(request) {
  const cache = await caches.open(MAP_CACHE_NAME);
  const cachedResponse = await cache.match(request);

  if (cachedResponse) {
    return cachedResponse;
  }

  try {
    const networkResponse = await fetch(request);

    // Armazena em cache apenas se for bem-sucedido
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone())
        .then(() => limitMapTileCache());
    }

    return networkResponse;
  } catch (error) {
    return new Response('Map tile not available', { status: 404 });
  }
}

// Manipula requisições de API
async function handleApiRequest(request) {
  try {
    return await fetch(request);
  } catch (error) {
    // Se offline, retorna dados mockados
    if (request.url.includes('/deliveries/') && request.url.includes('/status')) {
      return new Response(JSON.stringify({
        status: 'on_the_way',
        message: 'Você está offline. Estes dados não estão atualizados.'
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Tenta resposta em cache como último recurso
    const cachedResponse = await caches.match(request);
    return cachedResponse || new Response(JSON.stringify({
      error: 'Você está offline'
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Manipula assets estáticos
async function handleStaticAsset(request) {
  const cache = await caches.open(CACHE_NAME);
  const cachedResponse = await cache.match(request);

  if (cachedResponse) {
    return cachedResponse;
  }

  try {
    const networkResponse = await fetch(request);

    // Armazena em cache apenas se for bem-sucedido
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    // Se for uma página de navegação, retorna offline.html
    if (request.mode === 'navigate') {
      return caches.match('/tracking/offline.html');
    }

    // Falha definitiva
    return new Response('Resource not available offline', { status: 404 });
  }
}
