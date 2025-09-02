/**
 * NaviDelivery PWA - Tracking Application
 * 
 * Esta aplicação permite o rastreamento em tempo real
 * de entregas através de um token de rastreamento.
 */
class TrackingApp {
  constructor() {
    // Configurações
    this.apiBaseUrl = '/api/v1/public';
    this.refreshInterval = 15000; // 15 segundos
    this.map = null;
    this.markers = {};
    this.routeLine = null;
    this.refreshTimer = null;
    this.delivery = null;
    this.trackingToken = null;
    this.isOffline = !navigator.onLine;

    // Status do ciclo de vida da entrega
    this.lifecycleStages = [
      { id: 'pending', label: 'Pendente', icon: '⏳' },
      { id: 'preparing', label: 'Preparando', icon: '👨‍🍳' },
      { id: 'ready', label: 'Pronto', icon: '✅' },
      { id: 'assigned', label: 'Designado', icon: '🛵' },
      { id: 'on_the_way', label: 'A caminho', icon: '🚚' },
      { id: 'delivered', label: 'Entregue', icon: '📦' },
      { id: 'cancelled', label: 'Cancelado', icon: '❌' }
    ];

    // Elementos DOM
    this.elements = {
      loadingScreen: document.getElementById('loading-screen'),
      mainApp: document.getElementById('main-app'),
      connectionStatus: document.getElementById('connection-status'),
      offlineIndicator: document.getElementById('offline-indicator'),

      // Screens
      tokenScreen: document.getElementById('token-screen'),
      trackingScreen: document.getElementById('tracking-screen'),
      errorScreen: document.getElementById('error-screen'),

      // Token Form
      tokenForm: document.getElementById('token-form'),
      trackingTokenInput: document.getElementById('tracking-token'),
      tokenError: document.getElementById('token-error'),

      // Tracking Details
      orderCode: document.getElementById('order-code'),
      orderStatus: document.getElementById('order-status'),
      pickupAddress: document.getElementById('pickup-address'),
      dropoffAddress: document.getElementById('dropoff-address'),
      etaInfo: document.getElementById('eta-info'),
      etaTime: document.getElementById('eta-time'),
      progressTimeline: document.getElementById('progress-timeline'),

      // Courier Info
      additionalInfo: document.getElementById('additional-info'),
      courierName: document.getElementById('courier-name'),
      courierPhone: document.getElementById('courier-phone'),

      // Buttons
      backButton: document.getElementById('back-button'),
      retryButton: document.getElementById('retry-button')
    };

    // Iniciar a aplicação
    this.init();
  }

  /**
   * Inicializa a aplicação
   */
  init() {
    // Registrar event listeners
    this.registerEventListeners();

    // Verificar token na URL
    this.checkForTokenInUrl();

    // Verificar status de conexão
    this.updateConnectionStatus();

    // Exibir tela principal após carregamento
    setTimeout(() => {
      this.elements.loadingScreen.style.display = 'none';
      this.elements.mainApp.style.display = 'block';
    }, 1500);

    // Registrar service worker
    this.registerServiceWorker();
  }

  /**
   * Registra o service worker para funcionalidades offline
   */
  registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      window.addEventListener('load', () => {
        navigator.serviceWorker.register('./service-worker.js')
          .then(registration => {
            console.log('Service Worker registrado com sucesso:', registration.scope);
          })
          .catch(error => {
            console.error('Falha ao registrar Service Worker:', error);
          });
      });
    }
  }

  /**
   * Registra todos os event listeners necessários
   */
  registerEventListeners() {
    // Form de token
    this.elements.tokenForm.addEventListener('submit', (e) => {
      e.preventDefault();
      this.trackDelivery();
    });

    // Botão voltar
    this.elements.backButton.addEventListener('click', () => {
      this.showScreen('token');
      this.stopTracking();
    });

    // Botão tentar novamente
    this.elements.retryButton.addEventListener('click', () => {
      this.showScreen('token');
    });

    // Monitorar status de conexão
    window.addEventListener('online', () => {
      this.isOffline = false;
      this.updateConnectionStatus();
      if (this.trackingToken) {
        this.fetchDeliveryData(this.trackingToken);
      }
    });

    window.addEventListener('offline', () => {
      this.isOffline = true;
      this.updateConnectionStatus();
    });
  }

  /**
   * Verifica se há um token na URL
   */
  checkForTokenInUrl() {
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get('token');

    if (token) {
      this.elements.trackingTokenInput.value = token;
      this.trackDelivery();
    }
  }

  /**
   * Atualiza o indicador de status de conexão
   */
  updateConnectionStatus() {
    if (this.isOffline) {
      this.elements.connectionStatus.classList.add('offline');
      this.elements.connectionStatus.querySelector('.status-dot').style.backgroundColor = '#EF4444';
      this.elements.connectionStatus.querySelector('.status-text').textContent = 'Offline';
      this.elements.offlineIndicator.style.display = 'block';
    } else {
      this.elements.connectionStatus.classList.remove('offline');
      this.elements.connectionStatus.querySelector('.status-dot').style.backgroundColor = '#10B981';
      this.elements.connectionStatus.querySelector('.status-text').textContent = 'Online';
      this.elements.offlineIndicator.style.display = 'none';
    }
  }

  /**
   * Inicia o rastreamento da entrega com o token fornecido
   */
  trackDelivery() {
    const token = this.elements.trackingTokenInput.value.trim();

    if (!token) {
      this.showTokenError('Por favor, digite um código de rastreamento.');
      return;
    }

    this.trackingToken = token;
    this.fetchDeliveryData(token);
  }

  /**
   * Busca os dados da entrega na API
   */
  async fetchDeliveryData(token) {
    try {
      this.showLoading(true);

      const response = await fetch(`${this.apiBaseUrl}/deliveries/${token}`);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      this.delivery = data;

      // Inicializar a tela de rastreamento
      this.initializeTrackingView();
      this.showScreen('tracking');

      // Iniciar atualizações periódicas
      this.startTracking();
    } catch (error) {
      console.error('Erro ao buscar dados da entrega:', error);
      this.showScreen('error');
    } finally {
      this.showLoading(false);
    }
  }

  /**
   * Inicia atualizações periódicas do status da entrega
   */
  startTracking() {
    // Limpar qualquer timer existente
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
    }

    // Inicializar o mapa
    this.initializeMap();

    // Configurar atualizações periódicas
    this.refreshTimer = setInterval(() => {
      this.updateDeliveryStatus();
    }, this.refreshInterval);
  }

  /**
   * Para o rastreamento e limpa recursos
   */
  stopTracking() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = null;
    }

    if (this.map) {
      this.map.remove();
      this.map = null;
    }

    this.markers = {};
    this.routeLine = null;
    this.delivery = null;
  }

  /**
   * Atualiza o status atual da entrega
   */
  async updateDeliveryStatus() {
    if (!this.trackingToken || this.isOffline) return;

    try {
      const response = await fetch(`${this.apiBaseUrl}/deliveries/${this.trackingToken}/status`);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const statusData = await response.json();

      // Atualizar apenas dados relevantes
      const wasDelivered = this.delivery.status === 'delivered';
      const isNowDelivered = statusData.status === 'delivered';

      this.delivery.status = statusData.status;
      this.delivery.current_location = statusData.current_location;
      this.delivery.estimated_arrival = statusData.estimated_arrival;

      // Atualizar interface
      this.updateStatusDisplay();
      this.updateMapMarkers();

      // Notificar usuário se entrega foi concluída
      if (!wasDelivered && isNowDelivered) {
        this.notifyDelivered();
      }
    } catch (error) {
      console.error('Erro ao atualizar status:', error);
    }
  }

  /**
   * Inicializa a visualização de rastreamento
   */
  initializeTrackingView() {
    // Dados básicos
    this.elements.orderCode.textContent = `#${this.delivery.external_order_code || 'N/A'}`;
    this.updateStatusDisplay();

    // Endereços
    this.elements.pickupAddress.textContent = this.delivery.pickup_address || 'Endereço não disponível';
    this.elements.dropoffAddress.textContent = this.delivery.dropoff_address || 'Endereço não disponível';

    // Timeline de progresso
    this.renderTimeline();

    // Informações do entregador
    if (this.delivery.courier && this.delivery.status !== 'pending') {
      this.elements.courierName.textContent = this.delivery.courier.name || 'N/A';
      this.elements.courierPhone.textContent = this.delivery.courier.phone || 'N/A';
      this.elements.additionalInfo.style.display = 'block';
    } else {
      this.elements.additionalInfo.style.display = 'none';
    }
  }

  /**
   * Atualiza a exibição do status
   */
  updateStatusDisplay() {
    // Status badge
    this.elements.orderStatus.textContent = this.getStatusLabel(this.delivery.status);
    this.elements.orderStatus.className = `status ${this.delivery.status}`;

    // ETA (Tempo estimado de chegada)
    if (this.delivery.estimated_arrival && ['assigned', 'on_the_way'].includes(this.delivery.status)) {
      const estimatedTime = new Date(this.delivery.estimated_arrival);
      const now = new Date();

      if (estimatedTime > now) {
        const minutesDiff = Math.round((estimatedTime - now) / 60000);

        if (minutesDiff <= 60) {
          this.elements.etaTime.textContent = `${minutesDiff} min`;
        } else {
          const hours = Math.floor(minutesDiff / 60);
          const mins = minutesDiff % 60;
          this.elements.etaTime.textContent = `${hours}h ${mins}min`;
        }

        this.elements.etaInfo.style.display = 'flex';
      } else {
        this.elements.etaTime.textContent = 'Chegando';
        this.elements.etaInfo.style.display = 'flex';
      }
    } else {
      this.elements.etaInfo.style.display = 'none';
    }

    // Atualizar status da timeline
    this.updateTimelineStatus();
  }

  /**
   * Renderiza a timeline de progresso
   */
  renderTimeline() {
    // Limpar timeline atual
    this.elements.progressTimeline.innerHTML = '';

    // Filtrar apenas os estágios relevantes para esta entrega
    const relevantStages = this.lifecycleStages.filter(stage => {
      // Nunca mostrar "pending" na timeline
      if (stage.id === 'pending') return false;

      // Se foi cancelado, mostrar apenas "cancelado"
      if (this.delivery.status === 'cancelled') {
        return stage.id === 'cancelled';
      }

      // Se não, filtrar cancelado fora
      return stage.id !== 'cancelled';
    });

    // Criar elementos da timeline
    relevantStages.forEach(stage => {
      const item = document.createElement('div');
      item.className = 'timeline-item';
      item.dataset.status = stage.id;

      item.innerHTML = `
        <div class="timeline-icon">${stage.icon}</div>
        <div class="timeline-content">
          <div class="timeline-status">${stage.label}</div>
          <div class="timeline-time">--</div>
        </div>
      `;

      this.elements.progressTimeline.appendChild(item);
    });

    // Atualizar status
    this.updateTimelineStatus();
  }

  /**
   * Atualiza os status na timeline
   */
  updateTimelineStatus() {
    if (!this.delivery) return;

    const currentStatus = this.delivery.status;
    const timelineItems = this.elements.progressTimeline.querySelectorAll('.timeline-item');

    // Status ordenados por sequência
    const statusSequence = this.lifecycleStages.map(s => s.id);
    const currentIndex = statusSequence.indexOf(currentStatus);

    timelineItems.forEach(item => {
      const itemStatus = item.dataset.status;
      const itemIndex = statusSequence.indexOf(itemStatus);

      // Resetar classes
      item.classList.remove('active', 'completed');

      // Casos especiais
      if (currentStatus === 'cancelled') {
        if (itemStatus === 'cancelled') {
          item.classList.add('active');
        }
      } else {
        // Status normal em progresso
        if (itemIndex < currentIndex) {
          item.classList.add('completed');
        } else if (itemIndex === currentIndex) {
          item.classList.add('active');
        }
      }
    });
  }

  /**
   * Inicializa o mapa
   */
  initializeMap() {
    if (!this.delivery.pickup_lat || !this.delivery.pickup_lng || 
        !this.delivery.dropoff_lat || !this.delivery.dropoff_lng) {
      console.error('Coordenadas incompletas para o mapa');
      return;
    }

    // Criar mapa
    this.map = new maplibregl.Map({
      container: 'map',
      style: 'https://api.maptiler.com/maps/streets/style.json?key=get_your_own_key', // Substitua pela sua chave
      center: [
        (this.delivery.pickup_lng + this.delivery.dropoff_lng) / 2,
        (this.delivery.pickup_lat + this.delivery.dropoff_lat) / 2
      ],
      zoom: 12,
      attributionControl: false
    });

    // Adicionar controles de navegação
    this.map.addControl(new maplibregl.NavigationControl(), 'top-right');

    // Quando o mapa estiver pronto
    this.map.on('load', () => {
      this.updateMapMarkers();
    });
  }

  /**
   * Atualiza os markers no mapa
   */
  updateMapMarkers() {
    if (!this.map || !this.map.loaded()) return;

    // Adicionar ou atualizar marker da loja
    if (this.delivery.pickup_lat && this.delivery.pickup_lng) {
      this.addOrUpdateMarker('pickup', [this.delivery.pickup_lng, this.delivery.pickup_lat], 'store');
    }

    // Adicionar ou atualizar marker do destino
    if (this.delivery.dropoff_lat && this.delivery.dropoff_lng) {
      this.addOrUpdateMarker('dropoff', [this.delivery.dropoff_lng, this.delivery.dropoff_lat], 'destination');
    }

    // Adicionar ou atualizar marker do entregador
    if (this.delivery.current_location && 
        this.delivery.current_location.length === 2 && 
        ['assigned', 'on_the_way'].includes(this.delivery.status)) {

      const [lat, lng] = this.delivery.current_location;
      this.addOrUpdateMarker('courier', [lng, lat], 'courier');

      // Ajustar mapa para mostrar rota com entregador
      this.fitBounds();

      // Desenhar rota
      this.drawRoute();
    } else {
      // Remover marker do entregador se não estiver em rota
      if (this.markers.courier) {
        this.markers.courier.remove();
        delete this.markers.courier;
      }

      // Ajustar mapa para mostrar origem e destino
      this.fitBounds();

      // Desenhar rota direta
      this.drawRoute();
    }
  }

  /**
   * Adiciona ou atualiza um marker no mapa
   */
  addOrUpdateMarker(id, coordinates, type) {
    if (this.markers[id]) {
      this.markers[id].setLngLat(coordinates);
      return;
    }

    let el;

    if (type === 'courier') {
      el = document.createElement('div');
      el.className = 'courier-marker';

      // Adicionar pulse animation
      const pulse = document.createElement('div');
      pulse.className = 'pulse-circle';
      el.appendChild(pulse);

      // Ícone do entregador
      el.innerHTML += '🛵';
    } else {
      el = document.createElement('div');
      el.className = 'map-marker';

      if (type === 'store') {
        el.innerHTML = `<svg viewBox="0 0 24 24" width="30" height="30" fill="#3B82F6" stroke="white" stroke-width="1">
          <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
          <polyline points="9 22 9 12 15 12 15 22"></polyline>
        </svg>`;
      } else if (type === 'destination') {
        el.innerHTML = `<svg viewBox="0 0 24 24" width="30" height="30" fill="#EF4444" stroke="white" stroke-width="1">
          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
          <circle cx="12" cy="10" r="3"></circle>
        </svg>`;
      }
    }

    this.markers[id] = new maplibregl.Marker(el)
      .setLngLat(coordinates)
      .addTo(this.map);
  }

  /**
   * Ajusta os limites do mapa para mostrar todos os markers
   */
  fitBounds() {
    if (!this.map || Object.keys(this.markers).length < 2) return;

    const bounds = new maplibregl.LngLatBounds();

    // Adicionar todos os markers ao bounds
    Object.values(this.markers).forEach(marker => {
      bounds.extend(marker.getLngLat());
    });

    this.map.fitBounds(bounds, {
      padding: 60,
      maxZoom: 16,
      duration: 500
    });
  }

  /**
   * Desenha a rota no mapa
   */
  drawRoute() {
    if (!this.map || !this.map.loaded()) return;

    // Remover rota existente
    if (this.map.getSource('route')) {
      this.map.removeLayer('route');
      this.map.removeSource('route');
    }

    let points = [];

    // Se tiver entregador, desenhar rota do entregador até o destino
    if (this.markers.courier && this.markers.dropoff) {
      const courierPos = this.markers.courier.getLngLat();
      const dropoffPos = this.markers.dropoff.getLngLat();

      points = [
        [courierPos.lng, courierPos.lat],
        [dropoffPos.lng, dropoffPos.lat]
      ];
    } 
    // Senão, desenhar rota da loja até o destino
    else if (this.markers.pickup && this.markers.dropoff) {
      const pickupPos = this.markers.pickup.getLngLat();
      const dropoffPos = this.markers.dropoff.getLngLat();

      points = [
        [pickupPos.lng, pickupPos.lat],
        [dropoffPos.lng, dropoffPos.lat]
      ];
    }

    if (points.length >= 2) {
      // Adicionar a rota ao mapa
      this.map.addSource('route', {
        'type': 'geojson',
        'data': {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'LineString',
            'coordinates': points
          }
        }
      });

      this.map.addLayer({
        'id': 'route',
        'type': 'line',
        'source': 'route',
        'layout': {
          'line-join': 'round',
          'line-cap': 'round'
        },
        'paint': {
          'line-color': '#3B82F6',
          'line-width': 4,
          'line-opacity': 0.7,
          'line-dasharray': [1, 1]
        }
      });
    }
  }

  /**
   * Mostra uma mensagem de erro no formulário de token
   */
  showTokenError(message) {
    this.elements.tokenError.textContent = message;
    this.elements.tokenError.style.display = 'block';

    setTimeout(() => {
      this.elements.tokenError.style.display = 'none';
    }, 5000);
  }

  /**
   * Mostra/esconde o indicador de carregamento
   */
  showLoading(show) {
    if (show) {
      this.elements.loadingScreen.style.display = 'flex';
    } else {
      this.elements.loadingScreen.style.display = 'none';
    }
  }

  /**
   * Mostra uma tela específica
   */
  showScreen(screenName) {
    // Esconder todas as telas
    this.elements.tokenScreen.style.display = 'none';
    this.elements.trackingScreen.style.display = 'none';
    this.elements.errorScreen.style.display = 'none';

    // Mostrar a tela solicitada
    switch (screenName) {
      case 'token':
        this.elements.tokenScreen.style.display = 'flex';
        break;
      case 'tracking':
        this.elements.trackingScreen.style.display = 'flex';
        break;
      case 'error':
        this.elements.errorScreen.style.display = 'flex';
        break;
    }
  }

  /**
   * Retorna o label amigável para um status
   */
  getStatusLabel(status) {
    const stage = this.lifecycleStages.find(s => s.id === status);
    return stage ? stage.label : 'Desconhecido';
  }

  /**
   * Notifica o usuário quando a entrega for concluída
   */
  notifyDelivered() {
    // Verificar suporte a notificações
    if ('Notification' in window) {
      // Verificar permissão
      if (Notification.permission === 'granted') {
        this.showDeliveredNotification();
      } else if (Notification.permission !== 'denied') {
        Notification.requestPermission().then(permission => {
          if (permission === 'granted') {
            this.showDeliveredNotification();
          }
        });
      }
    }
  }

  /**
   * Mostra uma notificação de entrega concluída
   */
  showDeliveredNotification() {
    const notification = new Notification('Entrega Concluída', {
      body: `Sua entrega #${this.delivery.external_order_code} foi concluída!`,
      icon: './icons/icon-192x192.png'
    });

    notification.onclick = () => {
      window.focus();
      notification.close();
    };
  }
}

// Inicializar a aplicação quando o DOM estiver pronto
document.addEventListener('DOMContentLoaded', () => {
  window.app = new TrackingApp();
});
