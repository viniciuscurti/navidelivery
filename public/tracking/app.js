// App principal para tracking de entregas
class TrackingApp {
  constructor() {
    this.apiBase = '/api/v1/public';
    this.refreshInterval = 15000; // 15 segundos
    this.map = null;
    this.delivery = null;
    this.markers = {};
    this.routeLine = null;
    this.trackingToken = this.getTrackingToken();

    this.elements = {
      loading: document.getElementById('loading'),
      deliveryDetails: document.getElementById('deliveryDetails'),
      errorMessage: document.getElementById('errorMessage'),
      statusBadge: document.getElementById('statusBadge'),
      storeName: document.getElementById('storeName'),
      orderCode: document.getElementById('orderCode'),
      deliveryAddress: document.getElementById('deliveryAddress'),
      courierName: document.getElementById('courierName'),
      estimatedTime: document.getElementById('estimatedTime'),
      // Status timeline
      statusPreparing: document.getElementById('statusPreparing'),
      statusReady: document.getElementById('statusReady'),
      statusOnTheWay: document.getElementById('statusOnTheWay'),
      statusDelivered: document.getElementById('statusDelivered')
    };

    // Inicialização
    this.initMap();
    this.loadDeliveryData();

    // Polling para atualização em tempo real
    setInterval(() => this.updateDeliveryStatus(), this.refreshInterval);
  }

  // Obtém o token de tracking da URL
  getTrackingToken() {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('token');
  }

  // Inicializa o mapa
  initMap() {
    this.map = new maplibregl.Map({
      container: 'map',
      style: 'https://api.maptiler.com/maps/streets/style.json?key=get_your_own_key',
      center: [-46.6388, -23.5489], // São Paulo
      zoom: 12
    });

    this.map.addControl(new maplibregl.NavigationControl(), 'top-right');
    this.map.addControl(new maplibregl.GeolocateControl({
      positionOptions: { enableHighAccuracy: true },
      trackUserLocation: true
    }));
  }

  // Carrega os dados iniciais da entrega
  async loadDeliveryData() {
    if (!this.trackingToken) {
      this.showError('Token de rastreamento não fornecido');
      return;
    }

    try {
      const response = await fetch(`${this.apiBase}/deliveries/${this.trackingToken}`);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      this.delivery = await response.json();
      this.renderDeliveryDetails();
      this.updateMap();

      // Esconde o loading e mostra os detalhes
      this.elements.loading.classList.add('d-none');
      this.elements.deliveryDetails.classList.remove('d-none');
    } catch (error) {
      console.error('Erro ao carregar dados da entrega:', error);
      this.showError('Não foi possível carregar os dados da entrega');
    }
  }

  // Atualiza o status da entrega
  async updateDeliveryStatus() {
    if (!this.trackingToken) return;

    try {
      const response = await fetch(`${this.apiBase}/deliveries/${this.trackingToken}/status`);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const statusData = await response.json();

      // Atualiza apenas os dados de status
      this.delivery.status = statusData.status;
      this.delivery.current_location = statusData.current_location;
      this.delivery.estimated_arrival = statusData.estimated_arrival;

      // Atualiza a UI
      this.updateStatusDisplay();
      this.updateMap();
    } catch (error) {
      console.error('Erro ao atualizar status:', error);
    }
  }

  // Renderiza os detalhes da entrega na UI
  renderDeliveryDetails() {
    const { store, external_order_code, dropoff_address, courier, status } = this.delivery;

    this.elements.storeName.textContent = store?.name || 'Estabelecimento';
    this.elements.orderCode.textContent = `Pedido #${external_order_code || ''}`;
    this.elements.deliveryAddress.textContent = dropoff_address || 'Endereço não disponível';
    this.elements.courierName.textContent = courier?.name || 'A ser designado';

    this.updateStatusDisplay();
  }

  // Atualiza a exibição do status
  updateStatusDisplay() {
    const { status } = this.delivery;

    // Atualiza o badge de status
    this.elements.statusBadge.textContent = this.getStatusText(status);
    this.elements.statusBadge.className = `status-badge status-${status}`;

    // Atualiza o tempo estimado
    if (this.delivery.estimated_arrival) {
      const estimatedDate = new Date(this.delivery.estimated_arrival);
      const now = new Date();

      if (estimatedDate > now) {
        const minutesRemaining = Math.round((estimatedDate - now) / 60000);
        this.elements.estimatedTime.textContent = `${minutesRemaining} minutos`;
      } else {
        this.elements.estimatedTime.textContent = 'Chegando agora';
      }
    } else {
      this.elements.estimatedTime.textContent = 'Calculando...';
    }

    // Atualiza timeline de status
    this.updateStatusTimeline(status);
  }

  // Atualiza a timeline de status
  updateStatusTimeline(status) {
    // Reset
    [
      this.elements.statusPreparing,
      this.elements.statusReady,
      this.elements.statusOnTheWay,
      this.elements.statusDelivered
    ].forEach(el => {
      el.classList.remove('active', 'completed');
    });

    // Marca os status completos e o atual
    switch (status) {
      case 'delivered':
        this.elements.statusDelivered.classList.add('active');
        this.elements.statusOnTheWay.classList.add('completed');
        this.elements.statusReady.classList.add('completed');
        this.elements.statusPreparing.classList.add('completed');
        break;
      case 'on_the_way':
        this.elements.statusOnTheWay.classList.add('active');
        this.elements.statusReady.classList.add('completed');
        this.elements.statusPreparing.classList.add('completed');
        break;
      case 'ready':
        this.elements.statusReady.classList.add('active');
        this.elements.statusPreparing.classList.add('completed');
        break;
      case 'preparing':
      default:
        this.elements.statusPreparing.classList.add('active');
        break;
    }
  }

  // Retorna texto amigável para o status
  getStatusText(status) {
    const statusMap = {
      'pending': 'Pendente',
      'preparing': 'Preparando',
      'ready': 'Pronto para entrega',
      'assigned': 'Entregador designado',
      'on_the_way': 'A caminho',
      'delivered': 'Entregue',
      'cancelled': 'Cancelado'
    };

    return statusMap[status] || 'Desconhecido';
  }

  // Atualiza o mapa com as posições
  updateMap() {
    if (!this.delivery) return;

    const { pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, current_location } = this.delivery;

    // Adiciona/atualiza marker da loja
    if (pickup_lat && pickup_lng) {
      this.addOrUpdateMarker('store', [pickup_lng, pickup_lat], 'store-marker');
    }

    // Adiciona/atualiza marker do destino
    if (dropoff_lat && dropoff_lng) {
      this.addOrUpdateMarker('destination', [dropoff_lng, dropoff_lat], 'destination-marker');
    }

    // Adiciona/atualiza marker do entregador
    if (current_location && current_location.length === 2) {
      const [lat, lng] = current_location;
      this.addOrUpdateMarker('courier', [lng, lat], 'courier-marker');

      // Ajusta o mapa para mostrar o entregador
      if (this.markers.courier && this.markers.destination) {
        this.fitMapToMarkers([this.markers.courier, this.markers.destination]);
      }
    } else {
      // Se não tiver entregador, ajusta para loja e destino
      if (this.markers.store && this.markers.destination) {
        this.fitMapToMarkers([this.markers.store, this.markers.destination]);
      }
    }

    // Atualiza a linha de rota (apenas mock, em produção usar o route_polyline)
    this.updateRouteLine();
  }

  // Adiciona ou atualiza um marker no mapa
  addOrUpdateMarker(id, coordinates, className) {
    if (this.markers[id]) {
      this.markers[id].setLngLat(coordinates);
    } else {
      // Cria o elemento do marker
      const el = document.createElement('div');
      el.className = `marker ${className}`;

      // Adiciona o marker ao mapa
      this.markers[id] = new maplibregl.Marker(el)
        .setLngLat(coordinates)
        .addTo(this.map);
    }
  }

  // Atualiza a linha de rota
  updateRouteLine() {
    // Remove a linha existente
    if (this.routeLine) {
      this.map.removeLayer('route');
      this.map.removeSource('route');
      this.routeLine = null;
    }

    // Se tiver entregador e destino, cria uma linha simples
    if (this.markers.courier && this.markers.destination) {
      const courierPos = this.markers.courier.getLngLat();
      const destPos = this.markers.destination.getLngLat();

      // Adiciona uma linha direta (em produção usar route_polyline)
      this.map.addSource('route', {
        type: 'geojson',
        data: {
          type: 'Feature',
          properties: {},
          geometry: {
            type: 'LineString',
            coordinates: [
              [courierPos.lng, courierPos.lat],
              [destPos.lng, destPos.lat]
            ]
          }
        }
      });

      this.map.addLayer({
        id: 'route',
        type: 'line',
        source: 'route',
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#0d6efd',
          'line-width': 4,
          'line-opacity': 0.8,
          'line-dasharray': [2, 1]
        }
      });

      this.routeLine = true;
    }
  }

  // Ajusta o mapa para mostrar todos os markers
  fitMapToMarkers(markers) {
    if (!markers.length) return;

    const bounds = new maplibregl.LngLatBounds();

    markers.forEach(marker => {
      bounds.extend(marker.getLngLat());
    });

    this.map.fitBounds(bounds, {
      padding: 70,
      maxZoom: 15,
      duration: 500
    });
  }

  // Mostra mensagem de erro
  showError(message) {
    this.elements.loading.classList.add('d-none');
    this.elements.errorMessage.textContent = message;
    this.elements.errorMessage.classList.remove('d-none');
  }
}

// Inicializa a aplicação quando o DOM estiver pronto
document.addEventListener('DOMContentLoaded', () => {
  window.app = new TrackingApp();
});
