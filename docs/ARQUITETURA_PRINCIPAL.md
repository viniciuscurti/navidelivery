# Documentação Técnica - NaviDelivery API

## Visão Geral
Sistema de API para gestão e rastreamento de entregas em tempo real, desenvolvido em Ruby on Rails com integração ao Google Maps API, WebSockets e processamento assíncrono.

## Arquitetura Principal

### Modelos de Domínio (app/models)

#### Delivery
**Classe principal do sistema** - Representa uma entrega
- **Responsabilidades:**
  - Gerencia o ciclo de vida de uma entrega (created → assigned → en_route → delivered)
  - Integra com sistema de tracking em tempo real
  - Controla status e transições de estado
  - Calcula estimativas de tempo e distância

- **Principais Métodos:**
  - `tracking_service` - Retorna instância do RealTimeTrackingService
  - `tracking_link` - Gera link público para rastreamento
  - `tracking_data` - Dados completos para tracking
  - `update_courier_location!` - Atualiza localização do entregador
  - `broadcast_status_update!` - Envia atualizações via WebSocket

#### Courier
**Representa entregadores/motoboys**
- **Responsabilidades:**
  - Gerencia dados pessoais e localização do entregador
  - Geocodificação automática de endereços
  - Histórico de localizações (location_pings)

- **Principais Métodos:**
  - `current_location` - Última localização conhecida
  - `geocoded?` - Verifica se endereço foi geocodificado
  - `location_hash` - Coordenadas em formato hash

#### Customer
**Representa clientes finais**
- **Responsabilidades:**
  - Dados do cliente destinatário
  - Geocodificação automática de endereços
  - Integração com sistema de notificações

#### Store
**Representa lojas/pontos de coleta**
- **Responsabilidades:**
  - Dados da loja origem
  - Localização geocodificada
  - Gestão de entregas originadas

#### LocationPing
**Registro de localização em tempo real**
- **Responsabilidades:**
  - Armazena coordenadas GPS com timestamp
  - Histórico de movimento dos entregadores
  - Suporte a geometria PostGIS

### Services (app/services)

#### GoogleMapsService
**Integração com Google Maps API**
- **Responsabilidades:**
  - Geocodificação de endereços
  - Cálculo de rotas e distâncias
  - Estimativas de tempo (ETA)
  - Validação de endereços

- **Principais Métodos:**
  - `geocode(address)` - Converte endereço em coordenadas
  - `reverse_geocode(lat, lng)` - Converte coordenadas em endereço
  - `distance_matrix(origins, destinations)` - Calcula distância/tempo
  - `directions(origin, destination)` - Gera rota otimizada
  - `validate_address(address)` - Valida se endereço existe

#### RealTimeTrackingService
**Gerenciamento de tracking em tempo real**
- **Responsabilidades:**
  - Coordena tracking completo de entregas
  - Gera links públicos de rastreamento
  - Calcula progresso e ETA dinâmico
  - Detecta proximidade ao destino
  - Broadcasts via WebSocket

- **Principais Métodos:**
  - `generate_tracking_link` - Cria link público único
  - `tracking_data` - Dados completos para frontend
  - `update_courier_location(lat, lng)` - Atualiza posição em tempo real
  - `delivery_progress` - Calcula percentual de progresso (0-100%)
  - `real_time_estimates` - ETA e estimativas atualizadas

#### DeliveryRouteService
**Cálculos de rota para entregas**
- **Responsabilidades:**
  - Calcula rotas otimizadas
  - Gerencia múltiplas entregas por entregador
  - Geocodificação automática
  - Otimização de percursos

- **Principais Métodos:**
  - `calculate_delivery_route(delivery)` - Calcula rota da entrega
  - `optimize_multiple_deliveries(courier, deliveries)` - Otimiza sequência
  - `calculate_delivery_eta(delivery)` - Calcula ETA
  - `geocode_and_save(model)` - Geocodifica e salva coordenadas

### Jobs Assíncronos (app/jobs)

#### GoogleMapsProcessingJob
**Processamento assíncrono de operações do Google Maps**
- **Responsabilidades:**
  - Geocodificação em background
  - Cálculo de rotas sem bloquear requests
  - Atualização de ETA em tempo real
  - Otimização de rotas de entregadores

- **Ações Disponíveis:**
  - `geocode_delivery` - Geocodifica endereços da entrega
  - `calculate_route` - Calcula rota completa
  - `update_eta` - Atualiza estimativa de chegada
  - `optimize_courier_route` - Otimiza rota do entregador

#### TrackingNotificationJob
**Notificações automáticas de tracking**
- **Responsabilidades:**
  - Envia notificações baseadas em eventos
  - Integração com WebSocket para tempo real
  - Detecção de atrasos significativos
  - Alertas de proximidade

- **Tipos de Notificação:**
  - `courier_assigned` - Entregador designado
  - `pickup_completed` - Produto coletado
  - `en_route` - A caminho do destino
  - `arriving` - Chegando ao destino
  - `delivered` - Entrega concluída

#### CourierLocationSimulatorJob
**Simulador para testes de tracking**
- **Responsabilidades:**
  - Simula movimento de entregador
  - Gera dados de teste realistas
  - Demonstra funcionalidades em tempo real

### Channels WebSocket (app/channels)

#### TrackingChannel
**Canal WebSocket para tracking em tempo real**
- **Responsabilidades:**
  - Conexões em tempo real para clientes
  - Broadcast de atualizações de localização
  - Notificações instantâneas de status
  - Gestão de subscrições por entrega

### Controllers API (app/controllers/api)

#### Public::TrackingController
**API pública para tracking (sem autenticação)**
- **Endpoints:**
  - `GET /api/v1/public/track/:token` - Dados da entrega
  - `POST /api/v1/public/track/:token/location` - Atualizar localização
  - `GET /api/v1/public/track/:token/route` - Rota com histórico

#### Maps::MapsController
**API para funcionalidades do Google Maps**
- **Endpoints:**
  - `POST /api/v1/maps/geocode` - Geocodificar endereço
  - `POST /api/v1/maps/calculate_route` - Calcular rota
  - `POST /api/v1/maps/optimize_route` - Otimizar rota

## Fluxo Principal de Tracking

### 1. Criação da Entrega
```ruby
delivery = Delivery.create!(
  external_order_code: "ABC123",
  store: store,
  customer: customer,
  courier: courier,
  status: "assigned"
)
```

### 2. Geocodificação Automática
- Callbacks acionam GoogleMapsProcessingJob
- Endereços são geocodificados em background
- Coordenadas salvas nos models

### 3. Cálculo de Rota
```ruby
DeliveryRouteService.new.calculate_delivery_route(delivery)
```

### 4. Tracking em Tempo Real
```ruby
tracking_service = RealTimeTrackingService.new(delivery)
link = tracking_service.generate_tracking_link
```

### 5. Atualização de Localização
```ruby
delivery.update_courier_location!(latitude, longitude)
```

### 6. Broadcast WebSocket
- TrackingChannel envia atualizações
- Clientes recebem dados em tempo real
- ETA recalculado automaticamente

## Tecnologias Integradas

- **Google Maps API** - Geocodificação e rotas
- **PostGIS** - Geometria e cálculos espaciais
- **ActionCable** - WebSockets nativos do Rails
- **Sidekiq** - Jobs assíncronos
- **HTTParty** - Requisições HTTP para APIs externas
- **Redis** - Cache e filas de jobs

## Padrões Utilizados

- **Service Objects** - Lógica de negócio isolada
- **Background Jobs** - Processamento assíncrono
- **WebSocket Broadcasting** - Atualizações em tempo real
- **Clean Architecture** - Separação de responsabilidades
- **Observer Pattern** - Callbacks e notificações
- **Repository Pattern** - Acesso a dados estruturado
