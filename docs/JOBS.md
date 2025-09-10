# Documentação dos Jobs (Background Jobs)

## Jobs Principais

### GoogleMapsProcessingJob
**Processamento assíncrono de operações do Google Maps**

**Queue:** `default`
**Responsabilidades:**
- Geocodificação em background para não bloquear requests
- Cálculo de rotas assíncrono
- Atualização de ETA em tempo real
- Otimização de rotas de entregadores

**Ações Disponíveis:**

#### `geocode_delivery(delivery_id)`
Geocodifica endereços de loja e cliente da entrega
- **Processo:** Geocodifica store → Geocodifica customer → Calcula rota
- **Uso:** Callback automático ao criar entrega

#### `geocode_customer(customer_id)`
Geocodifica endereço específico do cliente
- **Uso:** Callback ao atualizar endereço do cliente

#### `geocode_store(store_id)`
Geocodifica endereço específico da loja
- **Uso:** Callback ao atualizar endereço da loja

#### `geocode_courier(courier_id)`
Geocodifica endereço base do entregador
- **Uso:** Callback ao cadastrar/atualizar entregador

#### `calculate_route(delivery_id)`
Calcula rota completa da entrega
- **Processo:** Extrai localizações → Calcula rota → Atualiza delivery → Broadcast WebSocket
- **Uso:** Após geocodificação ou atribuição de entregador

#### `update_eta(delivery_id, current_location)`
Atualiza ETA baseado na posição atual
- **Processo:** Calcula novo ETA → Atualiza delivery → Broadcast em tempo real
- **Uso:** A cada atualização de localização do entregador

#### `optimize_courier_route(courier_id)`
Otimiza sequência de entregas pendentes
- **Processo:** Busca entregas pendentes → Otimiza sequência → Atualiza route_order → Broadcast
- **Uso:** Quando entregador recebe múltiplas entregas

**Tratamento de Erros:**
- Logs estruturados para cada operação
- Falhas não param o processamento de outras operações
- Retry automático via Sidekiq para falhas temporárias

---

### TrackingNotificationJob
**Sistema de notificações automáticas**

**Queue:** `default`
**Responsabilidades:**
- Enviar notificações baseadas em eventos
- Integração com múltiplos canais (SMS, email, WhatsApp, WebSocket)
- Detecção de mudanças significativas de ETA
- Alertas de atraso

**Tipos de Notificação:**

#### `courier_assigned`
Notifica cliente sobre atribuição de entregador
- **Trigger:** Delivery.status → "assigned"
- **Conteúdo:** Link de tracking + informações do entregador

#### `pickup_completed`
Notifica coleta do produto na loja
- **Trigger:** Delivery.status → "en_route"
- **Conteúdo:** ETA inicial + link de tracking

#### `en_route`
Atualiza progresso da entrega
- **Trigger:** Posição do entregador atualizada
- **Conteúdo:** Percentual de progresso + ETA atualizado

#### `arriving`
Alerta de chegada iminente
- **Trigger:** Entregador a menos de 100m do destino
- **Conteúdo:** Alerta de chegada + preparação para recebimento

#### `delivered`
Confirmação de entrega realizada
- **Trigger:** Delivery.status → "delivered"
- **Conteúdo:** Confirmação + agradecimento

#### `eta_updated`
Mudanças significativas no ETA (>15 minutos)
- **Trigger:** Recálculo automático de ETA
- **Conteúdo:** Novo ETA + motivo da mudança

#### `delay_detected`
Atrasos detectados automaticamente
- **Trigger:** ETA ultrapassado + análise de trânsito
- **Conteúdo:** Tempo de atraso + nova estimativa

**Canais de Notificação:**
- **WebSocket:** Tempo real para clientes conectados
- **SMS/WhatsApp:** Notificações importantes
- **Email:** Confirmações e relatórios
- **Push Notifications:** Apps móveis

---

### RouteCalculationJob
**Cálculo de rotas otimizadas**

**Queue:** `routing`
**Retry Policy:** 5 tentativas com backoff exponencial
**Responsabilidades:**
- Calcular rotas entre pickup e dropoff
- Armazenar polyline para exibição em mapas
- Calcular distância e duração estimada
- Atualizar estimated_arrival_time

**Processo:**
1. Valida coordenadas de pickup e dropoff
2. Chama MapService.calculate_route
3. Atualiza campos de rota na delivery
4. Calcula estimated_arrival_time baseado na duração

**Campos Atualizados:**
- `route_polyline` - Polyline codificada para Google Maps
- `route_distance_meters` - Distância em metros
- `route_duration_seconds` - Duração estimada em segundos
- `estimated_arrival_time` - Timestamp de chegada estimado

---

### GeofenceCheckJob
**Detecção automática de chegada por geofence**

**Queue:** `default`
**Responsabilidades:**
- Verificar proximidade a pontos de pickup
- Detectar chegada ao destino (dropoff)
- Atualizar status automaticamente
- Disparar webhooks de eventos

**Geofences Monitorados:**

#### Pickup Geofence
- **Raio:** 50 metros (configurável via ENV)
- **Trigger:** LocationPing próximo ao pickup
- **Ação:** Status → "arrived_pickup"
- **Webhook:** `delivery.arrived_pickup`

#### Dropoff Geofence
- **Raio:** 50 metros (configurável via ENV)
- **Trigger:** LocationPing próximo ao dropoff
- **Ação:** Status → "arrived_dropoff"
- **Webhook:** `delivery.arrived_dropoff`

**Algoritmo:**
1. Calcula distância entre LocationPing e coordenadas
2. Verifica se distância <= raio do geofence
3. Valida status atual da entrega
4. Atualiza status e timestamp
5. Dispara webhook para integração

---

### CourierLocationSimulatorJob
**Simulador para testes e demonstrações**

**Queue:** `default`
**Responsabilidades:**
- Simular movimento realista de entregador
- Gerar dados de teste para desenvolvimento
- Demonstrar funcionalidades em tempo real
- Validar sistema de tracking

**Parâmetros:**
- `delivery_id` - ID da entrega para simular
- `start_lat, start_lng` - Coordenadas de início
- `end_lat, end_lng` - Coordenadas de destino
- `duration_minutes` - Duração total da simulação (padrão: 15 min)

**Algoritmo:**
1. Calcula pontos intermediários entre origem e destino
2. Atualiza localização a cada 30 segundos
3. Chama `delivery.update_courier_location!` para cada ponto
4. Simula finalização da entrega

**Uso:**
```ruby
CourierLocationSimulatorJob.perform_later(
  delivery.id, 
  store_lat, store_lng, 
  customer_lat, customer_lng,
  15 # minutos
)
```

---

### DeliveryStatusNotificationJob
**Notificações específicas de mudança de status**

**Queue:** `notifications`
**Responsabilidades:**
- Notificar mudanças de status via múltiplos canais
- Integração com sistemas externos via webhook
- Envio de emails transacionais
- Atualização de dashboards em tempo real

---

### TrackingViewJob
**Atualização de views de tracking**

**Queue:** `default`
**Responsabilidades:**
- Atualizar caches de dados de tracking
- Gerar snapshots para relatórios
- Manter histórico de eventos
- Preparar dados para dashboards

---

### LocationPingCleanupJob
**Limpeza de dados históricos**

**Queue:** `cleanup`
**Schedule:** Cron job diário
**Responsabilidades:**
- Remover location_pings antigos (>30 dias)
- Manter apenas dados necessários para análises
- Otimizar performance do banco
- Arquivar dados para relatórios

---

### SendTrackingLinkJob
**Envio de links de tracking**

**Queue:** `notifications`
**Responsabilidades:**
- Enviar link de tracking via SMS
- Email com informações da entrega
- WhatsApp com link personalizado
- Retry automático para falhas de entrega

## Configuração dos Jobs

### Filas (Queues)
- `default` - Jobs gerais e tracking
- `routing` - Cálculos de rota (CPU intensivo)
- `notifications` - Envio de notificações
- `cleanup` - Limpeza e manutenção

### Retry Policies
- **Exponential Backoff:** Para falhas temporárias de API
- **Max Attempts:** 3-5 tentativas dependendo do job
- **Dead Letter Queue:** Jobs que falharam definitivamente

### Monitoramento
- **Sidekiq Web UI:** `/sidekiq` (desenvolvimento)
- **Métricas:** Latência, throughput, taxa de erro
- **Alertas:** Jobs falhando ou com alta latência

### Performance
- **Batching:** Agrupar operações similares
- **Scheduling:** Jobs não críticos em horários de baixo uso
- **Timeouts:** Prevenir jobs que travaram

## Padrões dos Jobs

### Idempotência
- Jobs podem ser executados múltiplas vezes sem efeito colateral
- Validações antes de operações críticas
- Estados intermediários bem definidos

### Error Handling
- Logs estruturados com contexto completo
- Notificação de erros críticos
- Fallback para operações essenciais

### Testing
- Jobs testáveis com perform_now
- Mocks para APIs externas
- Asserções sobre side effects
