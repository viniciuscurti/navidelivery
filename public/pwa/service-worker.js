/**
 * NaviDelivery PWA - Service Worker
 * 
 * Este service worker gerencia o cache e as funcionalidades
 * offline da aplicação de rastreamento de entregas.
 */

// Versão do cache
const CACHE_NAME = 'navidelivery-tracking-v1';

// Arquivos essenciais para funcionamento offline
const STATIC_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './styles/app.css',
  './js/app.js',
  './icons/icon-192x192.png',
  './icons/icon-512x512.png'
];

// Recursos externos
const EXTERNAL_ASSETS = [
  'https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.js',
  'https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css'
];

// Instalação do Service Worker
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Caching app shell and content');
        return cache.addAll([...STATIC_ASSETS, ...EXTERNAL_ASSETS]);
      })
      .then(() => self.skipWaiting())
  );
});

// Ativação e limpeza de caches antigos
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(cacheNames => {
        return Promise.all(
          cacheNames
            .filter(cacheName => cacheName !== CACHE_NAME)
            .map(cacheName => caches.delete(cacheName))
        );
      })
      .then(() => self.clients.claim())
  );
});

// Interceptação de requisições
self.addEventListener('fetch', event => {
  const requestUrl = new URL(event.request.url);

  // Tratamento para requisições à API
  if (requestUrl.pathname.includes('/api/')) {
    event.respondWith(networkFirstStrategy(event.request));
    return;
  }

  // Tratamento para assets do mapa
  if (event.request.url.includes('api.maptiler.com') || 
      event.request.url.includes('tile.openstreetmap.org')) {
    event.respondWith(cacheFirstMapTiles(event.request));
    return;
  }

  // Tratamento para navegação
  if (event.request.mode === 'navigate') {
    event.respondWith(networkFirstWithOfflineFallback(event.request));
    return;
  }

  // Tratamento para outros assets estáticos
  event.respondWith(cacheFirst(event.request));
});

/**
 * Estratégia Network First para recursos dinâmicos
 * Tenta a rede primeiro, com fallback para cache
 */
async function networkFirstStrategy(request) {
  try {
    // Tentar obter da rede
    const networkResponse = await fetch(request);

    // Armazenar no cache se for bem-sucedido
    const cache = await caches.open(CACHE_NAME);
    cache.put(request, networkResponse.clone());

    return networkResponse;
  } catch (error) {
    // Fallback para cache
    const cachedResponse = await caches.match(request);

    if (cachedResponse) {
      return cachedResponse;
    }

    // Se for uma API e não tiver cache, retornar resposta offline
    if (request.url.includes('/api/')) {
      return createOfflineApiResponse();
    }

    throw error;
  }
}

/**
 * Estratégia Cache First para assets estáticos
 * Verifica o cache primeiro, recorrendo à rede se necessário
 */
async function cacheFirst(request) {
  const cachedResponse = await caches.match(request);

  if (cachedResponse) {
    return cachedResponse;
  }

  try {
    const networkResponse = await fetch(request);

    // Armazenar no cache apenas se for bem-sucedido
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    // Se for um recurso crucial (CSS, JS), tentar o cache geral
    const extension = request.url.split('.').pop();
    if (['css', 'js', 'html', 'json'].includes(extension)) {
      return caches.match('./index.html');
    }

    throw error;
  }
}

/**
 * Estratégia específica para tiles de mapas
 * Cache-first com atualização em background e controle de TTL
 */
async function cacheFirstMapTiles(request) {
  const cachedResponse = await caches.match(request);

  if (cachedResponse) {
    // Verificar TTL (7 dias)
    const cachedDate = new Date(cachedResponse.headers.get('date'));
    const now = new Date();
    const ONE_WEEK = 7 * 24 * 60 * 60 * 1000;

    // Se o cache não estiver expirado, use-o
    if (now.getTime() - cachedDate.getTime() < ONE_WEEK) {
      // Atualizar em background
      refreshCache(request);
      return cachedResponse;
    }
  }

  // Se não tiver no cache ou estiver expirado
  try {
    const networkResponse = await fetch(request);

    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    // Usar cache mesmo expirado se a rede falhar
    if (cachedResponse) {
      return cachedResponse;
    }

    // Criar resposta transparente (tile vazio)
    return new Response(null, {
      status: 204,
      statusText: 'No Content'
    });
  }
}

/**
 * Atualiza o cache em background sem bloquear
 */
function refreshCache(request) {
  setTimeout(() => {
    fetch(request)
      .then(response => {
        if (response.ok) {
          caches.open(CACHE_NAME)
            .then(cache => cache.put(request, response));
        }
      })
      .catch(() => {/* ignorar erros */});
  }, 1000);
}

/**
 * Estratégia Network First com fallback para página offline
 * para navegação
 */
async function networkFirstWithOfflineFallback(request) {
  try {
    // Tentar obter da rede
    const networkResponse = await fetch(request);

    // Armazenar no cache
    const cache = await caches.open(CACHE_NAME);
    cache.put(request, networkResponse.clone());

    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);

    if (cachedResponse) {
      return cachedResponse;
    }

    // Fallback para a página principal
    return caches.match('./index.html');
  }
}

/**
 * Cria uma resposta offline para APIs
 */
function createOfflineApiResponse() {
  const data = {
    offline: true,
    message: 'Você está offline. Os dados podem estar desatualizados.'
  };

  return new Response(JSON.stringify(data), {
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store'
    },
    status: 200
  });
}

// Evento de sincronização em background
self.addEventListener('sync', event => {
  if (event.tag === 'sync-tracking-data') {
    event.waitUntil(syncTrackingData());
  }
});

/**
 * Sincroniza dados de rastreamento quando a conexão volta
 */
async function syncTrackingData() {
  // Buscar requisições enfileiradas do IndexedDB
  // Implementação depende do seu sistema de enfileiramento
  console.log('Sincronizando dados após reconexão');
}

// Evento de notificação push
self.addEventListener('push', event => {
  let data = {};

  try {
    data = event.data.json();
  } catch (e) {
    data = {
      title: 'Atualização de Entrega',
      body: 'Sua entrega foi atualizada.'
    };
  }

  const options = {
    body: data.body || 'Confira o status da sua entrega',
    icon: './icons/icon-192x192.png',
    badge: './icons/icon-192x192.png',
    data: {
      url: data.url || './'
    },
    vibrate: [100, 50, 100]
  };

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// Evento de clique em notificação
self.addEventListener('notificationclick', event => {
  event.notification.close();

  // Abrir a URL específica ou a página principal
  const urlToOpen = event.notification.data && 
                   event.notification.data.url ? 
                   event.notification.data.url : './';

  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then(clientList => {
      // Verificar se já há uma janela aberta e focar nela
      for (const client of clientList) {
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus();
        }
      }

      // Se não, abrir nova janela
      return clients.openWindow(urlToOpen);
    })
  );
});
