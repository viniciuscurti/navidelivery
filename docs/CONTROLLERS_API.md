# Documentação dos Controllers e Integração API

## Controllers Principais

### API::V1::Public::TrackingController
**API pública para tracking (sem autenticação)**

**Responsabilidades:**
- Endpoints públicos acessíveis via token único
- Dados de tracking para clientes finais
- Atualização de localização do entregador
- Subscrição para WebSocket

**Endpoints:**

#### `GET /api/v1/public/track/:token`
Dados completos da entrega para tracking
- **Autenticação:** Token público da entrega
- **Retorna:** Delivery, route, courier, eta, status, timeline
- **Uso:** Página principal de tracking do cliente

#### `POST /api/v1/public/track/:token/location`
Atualização de localização do entregador
- **Parâmetros:** `latitude`, `longitude`
- **Efeitos:** Cria LocationPing, recalcula ETA, broadcast WebSocket
- **Uso:** App do entregador enviando coordenadas GPS

#### `GET /api/v1/public/track/:token/route`
Rota completa com histórico de movimento
- **Retorna:** Polyline, coordenadas históricas, estimativas
- **Uso:** Exibir rota no mapa com trilha do entregador

#### `GET /api/v1/public/track/:token/timeline`
Timeline de eventos da entrega
- **Retorna:** Histórico de status com timestamps
- **Uso:** Mostrar progresso cronológico

#### `POST /api/v1/public/track/:token/subscribe`
Informações para conexão WebSocket
- **Retorna:** Canal WebSocket e URL de conexão
- **Uso:** Estabelecer conexão em tempo real

---

### API::V1::MapsController
**API para operações do Google Maps (autenticada)**

**Responsabilidades:**
- Geocodificação de endereços
- Validação de endereços
- Cálculo de rotas e distâncias
- Otimização de rotas

**Endpoints:**

#### `POST /api/v1/maps/geocode`
Geocodificar endereço
- **Parâmetros:** `address`
- **Retorna:** Coordenadas, endereço formatado, place_id
- **Uso:** Validar e geocodificar endereços em formulários

#### `POST /api/v1/maps/validate_address`
Validar existência de endereço
- **Parâmetros:** `address`
- **Retorna:** Boolean de validade
- **Uso:** Validação em tempo real de formulários

#### `POST /api/v1/maps/calculate_route`
Calcular rota para entrega
- **Parâmetros:** `delivery_id`
- **Processo:** Agenda job assíncrono
- **Retorna:** Status 202 (Accepted)
- **Uso:** Recalcular rota após mudanças

#### `POST /api/v1/maps/update_eta`
Atualizar ETA da entrega
- **Parâmetros:** `delivery_id`, `current_location` (opcional)
- **Processo:** Agenda job assíncrono
- **Uso:** Recálculo manual de ETA

#### `POST /api/v1/maps/optimize_route`
Otimizar rota do entregador
- **Parâmetros:** `courier_id`
- **Processo:** Otimiza todas as entregas pendentes
- **Uso:** Maximizar eficiência de entregadores

#### `GET /api/v1/maps/calculate_distance`
Calcular distância entre dois pontos
- **Parâmetros:** `origin`, `destination`
- **Retorna:** Distância e tempo
- **Uso:** Estimativas rápidas

---

### DeliveriesController
**CRUD principal de entregas**

**Responsabilidades:**
- Criar, listar, atualizar entregas
- Atribuir entregadores
- Atualizar status
- Receber pings de localização

**Principais Actions:**
- `create` - Nova entrega com geocodificação automática
- `assign` - Atribuir entregador e calcular rota
- `pings` - Receber atualizações de localização
- `status` - Atualizar status da entrega

---

## Channels WebSocket

### TrackingChannel
**Canal WebSocket para tracking em tempo real**

**Responsabilidades:**
- Conexões persistentes para clientes
- Broadcast de atualizações de localização
- Notificações instantâneas
- Dados iniciais ao conectar

**Subscription:**
```javascript
cable.subscriptions.create({
  channel: 'TrackingChannel',
  delivery_token: 'token_da_entrega'
}, {
  received(data) {
    // Receber atualizações em tempo real
  }
});
```

**Tipos de Mensagem:**
- `initial_data` - Dados completos ao conectar
- `location_update` - Nova posição do entregador
- `status_update` - Mudança de status
- `eta_updated` - ETA recalculado
- `notification` - Notificações importantes

---

## Integrações Externas

### Google Maps API
**APIs utilizadas:**
- **Geocoding API** - Endereços ↔ Coordenadas
- **Distance Matrix API** - Distâncias e tempos
- **Directions API** - Rotas otimizadas
- **Places API** - Validação de endereços

**Rate Limiting:**
- 50 requests/segundo (configurável)
- Burst de até 100 requests
- Retry automático com backoff

### WhatsApp Business API
**Notificações via WhatsApp:**
- Templates pré-aprovados
- Links de tracking personalizados
- Status de entrega das mensagens
- Fallback para SMS

### WebSocket (ActionCable)
**Tempo real nativo do Rails:**
- Conexões persistentes
- Broadcast para múltiplos clientes
- Reconexão automática
- Autenticação por token

---

## Fluxo Completo de Integração

### 1. Criação da Entrega
```ruby
POST /api/v1/deliveries
{
  "external_order_code": "ABC123",
  "store_id": 1,
  "customer": {
    "name": "João Silva",
    "phone": "+5511999999999",
    "address": "Rua das Flores, 123"
  }
}
```

### 2. Geocodificação Automática
- `GoogleMapsProcessingJob.perform_later('geocode_delivery', delivery.id)`
- Coordenadas salvas em `customers` e `stores`

### 3. Atribuição de Entregador
```ruby
POST /api/v1/deliveries/123/assign
{
  "courier_id": 456
}
```

### 4. Cálculo de Rota
- `GoogleMapsProcessingJob.perform_later('calculate_route', delivery.id)`
- Rota salva em campos da `delivery`

### 5. Cliente Acessa Tracking
```
GET /track/TOKEN_PUBLICO
```

### 6. Conexão WebSocket
```javascript
// Frontend conecta automaticamente
const cable = ActionCable.createConsumer('/cable');
```

### 7. Entregador Atualiza Localização
```ruby
POST /api/v1/public/track/TOKEN/location
{
  "latitude": -23.5505,
  "longitude": -46.6333
}
```

### 8. Broadcast Tempo Real
- LocationPing criado
- ETA recalculado
- WebSocket broadcast para todos os clientes conectados

### 9. Detecção Automática
- GeofenceCheckJob verifica proximidade
- Status atualizado automaticamente
- Notificações enviadas

### 10. Finalização
- Status → "delivered"
- Tracking finalizado
- Relatórios e métricas atualizados

---

## Segurança e Autenticação

### Endpoints Públicos
- Autenticação via token público único
- Tokens não expiram durante vida útil da entrega
- Rate limiting por IP

### Endpoints Autenticados
- JWT tokens para API
- Devise para interface web
- Scoping por account (multi-tenancy)

### Validações
- Sanitização de parâmetros
- Validação de coordenadas GPS
- Rate limiting por usuário/account

---

## Monitoramento e Observabilidade

### Métricas
- Latência de APIs
- Taxa de sucesso de geocodificação
- Conexões WebSocket ativas
- Jobs em background

### Logs
- Structured logging (JSON)
- Request/response tracking
- Error tracking com contexto
- Performance profiling

### Alertas
- APIs externas indisponíveis
- Jobs falhando consistentemente
- WebSocket desconexões em massa
- Coordenadas GPS inválidas
