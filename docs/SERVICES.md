# Documentação dos Services

## Services Principais

### GoogleMapsService
**Integração principal com Google Maps API**

**Responsabilidades:**
- Comunicação com todas as APIs do Google Maps
- Geocodificação de endereços
- Cálculo de rotas e distâncias
- Validação de endereços
- Estimativas de tempo (ETA)

**Principais Métodos:**

#### `geocode(address)`
Converte endereço em coordenadas geográficas
- **Parâmetros:** `address` (String) - Endereço para geocodificar
- **Retorna:** Hash com success/error e dados de localização
- **Uso:** Validar e obter coordenadas de endereços de clientes/lojas

#### `reverse_geocode(lat, lng)`
Converte coordenadas em endereço formatado
- **Parâmetros:** `lat, lng` (Float) - Coordenadas geográficas
- **Retorna:** Hash com endereço formatado
- **Uso:** Obter endereço legível a partir de coordenadas GPS

#### `distance_matrix(origins, destinations, options = {})`
Calcula distância e tempo entre múltiplos pontos
- **Parâmetros:** 
  - `origins` (Array) - Pontos de origem
  - `destinations` (Array) - Pontos de destino
  - `options` (Hash) - Opções como modo de transporte, trânsito
- **Retorna:** Matriz com distâncias e tempos
- **Uso:** Calcular ETAs dinâmicos e comparar rotas

#### `directions(origin, destination, options = {})`
Gera rota otimizada entre dois pontos
- **Parâmetros:** Origem, destino e opções de rota
- **Retorna:** Rota completa com polyline e instruções
- **Uso:** Exibir rota no mapa para cliente

#### `validate_address(address)`
Valida se endereço existe e é acessível
- **Retorna:** Boolean indicando validade
- **Uso:** Validar endereços antes de criar entregas

#### `calculate_eta(origin, destination, options = {})`
Calcula estimativa de chegada considerando trânsito atual
- **Retorna:** Hash com distância, duração e duração com trânsito
- **Uso:** ETAs em tempo real para clientes

**Configuração:**
- Requer `GOOGLE_MAPS_API_KEY` configurada
- Base URI: `https://maps.googleapis.com/maps/api`
- Usa HTTParty para requisições HTTP

---

### RealTimeTrackingService
**Coordenador principal do tracking em tempo real**

**Responsabilidades:**
- Orquestra todo o sistema de tracking
- Gera links públicos de rastreamento
- Calcula progresso e métricas em tempo real
- Gerencia broadcasts via WebSocket
- Detecta eventos automáticos (chegada, atraso)

**Principais Métodos:**

#### `generate_tracking_link`
Gera URL pública única para tracking
- **Retorna:** String com URL completa
- **Uso:** Enviar link via SMS/email para cliente

#### `tracking_data`
Compila todos os dados necessários para frontend
- **Retorna:** Hash completo com delivery, route, courier, eta, status, timeline
- **Uso:** Alimentar página de tracking do cliente

#### `update_courier_location(latitude, longitude)`
Atualiza posição do entregador em tempo real
- **Parâmetros:** Coordenadas GPS atuais
- **Efeitos:** 
  - Cria LocationPing no banco
  - Recalcula ETA em background
  - Verifica proximidade ao destino
  - Faz broadcast via WebSocket
- **Uso:** Chamado pelo app do entregador

#### `delivery_progress`
Calcula percentual de progresso (0-100%)
- **Algoritmo:** Baseado em ETA atual vs. estimativa inicial
- **Fallback:** Status-based para entregas sem ETA
- **Retorna:** Integer (0-100)

#### `real_time_estimates`
Métricas atualizadas dinamicamente
- **Retorna:** ETA atual, progresso, distância restante, última atualização
- **Uso:** Atualizar interface do cliente em tempo real

#### `check_arrival_proximity(latitude, longitude)`
Detecta automaticamente quando entregador está chegando
- **Threshold:** 100 metros do destino
- **Efeito:** Muda status para "arriving" e notifica cliente
- **Uso:** Alertas automáticos de chegada

---

### DeliveryRouteService
**Especialista em cálculos de rota para entregas**

**Responsabilidades:**
- Calcular rotas otimizadas
- Gerenciar múltiplas entregas por entregador
- Geocodificação automática de modelos
- Otimização de sequência de entregas

**Principais Métodos:**

#### `calculate_delivery_route(delivery)`
Calcula rota completa da loja ao cliente
- **Processo:** Extrai localizações → Chama Google Maps → Parseia dados → Atualiza delivery
- **Salva:** `estimated_distance`, `estimated_duration`, `route_polyline`
- **Uso:** Ao atribuir entregador ou criar entrega

#### `calculate_delivery_eta(delivery, current_location = nil)`
Calcula ETA baseado na posição atual
- **Flexível:** Usa localização atual do entregador ou posição específica
- **Atualiza:** `estimated_arrival_at`, `current_estimated_duration`
- **Uso:** Recálculos dinâmicos durante entrega

#### `optimize_multiple_deliveries(courier, deliveries)`
Otimiza sequência de múltiplas entregas
- **Algoritmo:** Usa Google Maps Waypoint Optimization
- **Resultado:** Reordena entregas na sequência mais eficiente
- **Atualiza:** Campo `route_order` em cada delivery
- **Uso:** Maximizar eficiência de entregadores

#### `geocode_and_save(model, address_field = :address)`
Geocodifica endereço e salva coordenadas no modelo
- **Universale:** Funciona com Customer, Store, Courier
- **Campos atualizados:** `latitude`, `longitude`, `geocoded_at`
- **Uso:** Callbacks automáticos ou geocodificação manual

#### `validate_customer_address(address)`
Valida endereço antes de criar entrega
- **Integração:** Usa GoogleMapsService.validate_address
- **Uso:** Validação em formulários de criação

#### `calculate_distance(point_a, point_b)`
Calcula distância e tempo entre dois pontos
- **Retorna:** Distância em texto/metros, duração em texto/segundos
- **Uso:** Métricas e comparações de rotas

#### `courier_near_destination?(courier_location, destination, threshold = 100)`
Verifica se entregador está próximo do destino
- **Threshold padrão:** 100 metros
- **Uso:** Detecção automática de chegada

---

### DeliveryStatusService
**Gerenciador de transições de status**

**Responsabilidades:**
- Validar transições de status permitidas
- Executar side-effects de mudanças
- Agendar jobs relacionados
- Manter integridade do ciclo de vida

**Padrão Interactor:**
- Usa gem Interactor para operações complexas
- Context com success/failure
- Rollback automático em caso de erro

**Fluxo Principal:**
1. `validate_transition!` - Verifica se transição é válida
2. `update_delivery_status!` - Atualiza status no banco
3. `handle_side_effects!` - Executa ações relacionadas

**Side Effects por Status:**
- `assigned` → Agenda cálculo de rota
- `en_route` → Inicia tracking em tempo real
- `delivered/canceled` → Para tracking e finaliza

---

### WhatsAppNotifier
**Integração com WhatsApp Business API**

**Responsabilidades:**
- Envio de mensagens via WhatsApp
- Templates de mensagem por tipo de evento
- Formatação de links de tracking
- Tratamento de erros de entrega

**Uso:** Notificações importantes para clientes via WhatsApp

---

### CourierAppSimulator
**Simulador para testes e demonstração**

**Responsabilidades:**
- Simular movimento de entregador
- Gerar dados realistas para testes
- Demonstrar funcionalidades em tempo real

**Uso:** Development e demonstrações do sistema

## Padrões dos Services

### Inicialização
- Services instanciam dependências no `initialize`
- GoogleMapsService sempre injetado em services de rota

### Tratamento de Erros
- Logs estruturados para falhas
- Retorno consistente com `success: boolean`
- Graceful degradation quando APIs externas falham

### Integração com Jobs
- Operações pesadas delegadas para background jobs
- Services focam em lógica, Jobs focam em execução

### Testabilidade
- Dependências injetáveis
- Métodos públicos com responsabilidade única
- Fácil mock de APIs externas
