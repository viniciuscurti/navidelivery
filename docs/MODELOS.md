# Documentação dos Modelos (Models)

## Modelos Principais

### Account
**Multi-tenancy - Conta organizacional**

**Responsabilidades:**
- Isola dados entre diferentes organizações/empresas
- Controla limites de uso e assinaturas
- Gerencia status da conta (ativa, suspensa, cancelada)

**Relacionamentos:**
- `has_many :stores` - Lojas da conta
- `has_many :users` - Usuários da conta
- `has_many :couriers` - Entregadores da conta
- `has_many :deliveries` - Entregas (através das lojas)
- `has_one :subscription` - Plano de assinatura

**Principais Métodos:**
- `active_deliveries_count` - Conta entregas ativas
- `monthly_deliveries_count` - Entregas do mês atual
- `within_limits?` - Verifica se está dentro dos limites da assinatura

**Status Disponíveis:**
- `active` - Conta ativa e funcional
- `suspended` - Temporariamente suspensa
- `canceled` - Cancelada permanentemente

---

### User
**Usuários do sistema com autenticação**

**Responsabilidades:**
- Autenticação via Devise (email/senha)
- Controle de acesso por roles
- Gestão de API tokens para integração

**Relacionamentos:**
- `belongs_to :account` - Conta organizacional
- `has_many :deliveries` - Entregas criadas pelo usuário

**Roles Disponíveis:**
- `user` - Usuário básico (padrão)
- `store_manager` - Gerente de loja
- `courier` - Entregador
- `admin` - Administrador da conta
- `super_admin` - Super administrador do sistema

**Status Disponíveis:**
- `active` - Usuário ativo (padrão)
- `inactive` - Usuário inativo
- `suspended` - Usuário suspenso

**Principais Métodos:**
- `full_name` - Nome completo concatenado
- `super_admin?` - Verifica se é super admin
- `generate_api_token` - Gera token para API

**Validações:**
- Email único e formato válido
- Telefone obrigatório com formato internacional
- Nome e sobrenome obrigatórios
- Conta obrigatória (exceto super_admin)

---

### Delivery
**Entidade central - Representa uma entrega**

**Responsabilidades:**
- Controla ciclo de vida da entrega
- Integra com sistema de tracking em tempo real
- Gerencia coordenadas de origem e destino
- Calcula estimativas e progresso

**Relacionamentos:**
- `belongs_to :account` - Conta proprietária
- `belongs_to :store` - Loja de origem
- `belongs_to :courier` - Entregador (opcional)
- `belongs_to :user` - Usuário que criou
- `belongs_to :customer` - Cliente destinatário
- `has_many :location_pings` - Histórico de localizações
- `has_one :route` - Rota calculada

**Status Disponíveis:**
```ruby
STATUSES = %w[
  created assigned en_route arrived_pickup
  left_pickup arrived_dropoff delivered canceled
]
```

**Principais Métodos:**
- `tracking_service` - Instância do RealTimeTrackingService
- `tracking_link` - Link público para rastreamento
- `tracking_data` - Dados completos para frontend
- `update_courier_location!(lat, lng)` - Atualiza posição do entregador
- `delivery_progress` - Percentual de progresso (0-100%)
- `broadcast_status_update!` - Envia atualizações via WebSocket
- `trackable?` - Verifica se pode ser rastreado
- `in_progress?` - Verifica se está em andamento

**Validações:**
- Código externo único por loja
- Coordenadas de origem e destino obrigatórias
- Status deve estar na lista permitida

**Callbacks:**
- `before_create :generate_public_token` - Gera token público único
- `after_update :broadcast_status_change` - Broadcast mudanças de status

---

### Courier
**Entregadores/Motoboys**

**Responsabilidades:**
- Dados pessoais e contato do entregador
- Localização atual e histórico de movimento
- Geocodificação automática de endereços
- Integração com sistema de tracking

**Relacionamentos:**
- `belongs_to :account` - Conta proprietária
- `has_many :deliveries` - Entregas atribuídas
- `has_many :location_pings` - Histórico de localizações

**Principais Métodos:**
- `current_location` - Última localização conhecida (GPS ou endereço)
- `geocoded?` - Verifica se endereço foi geocodificado
- `location_hash` - Coordenadas em formato hash {lat:, lng:}
- `coordinates` - Array [latitude, longitude]

**Geocodificação Automática:**
- `after_create :geocode_address_async` - Geocodifica ao criar
- `after_update :geocode_address_if_changed` - Geocodifica se endereço mudou

**Scopes:**
- `geocoded` - Couriers com coordenadas
- `not_geocoded` - Couriers sem coordenadas
- `with_pending_deliveries` - Com entregas pendentes

---

### Customer
**Clientes destinatários**

**Responsabilidades:**
- Dados do cliente final
- Endereço de entrega e geocodificação
- Integração com notificações

**Relacionamentos:**
- `belongs_to :account` - Conta proprietária
- `has_many :deliveries` - Entregas destinadas ao cliente

**Principais Métodos:**
- `geocoded?` - Verifica se endereço foi geocodificado
- `location_hash` - Coordenadas em formato hash
- `coordinates` - Array de coordenadas

**Validações:**
- Nome obrigatório
- Telefone obrigatório

---

### Store
**Lojas/Pontos de coleta**

**Responsabilidades:**
- Dados da loja origem
- Localização geocodificada
- Gestão de entregas originadas

**Relacionamentos:**
- `belongs_to :account` - Conta proprietária
- `has_many :deliveries` - Entregas originadas na loja

**Principais Métodos:**
- `geocoded?` - Verifica se foi geocodificado
- `location_hash` - Coordenadas em hash
- `location_from_coordinates` - Point PostGIS

---

### LocationPing
**Registro de localização GPS**

**Responsabilidades:**
- Armazena coordenadas GPS com timestamp
- Histórico de movimento dos entregadores
- Integração com PostGIS para cálculos geoespaciais

**Relacionamentos:**
- `belongs_to :courier` - Entregador
- `belongs_to :delivery` - Entrega relacionada (opcional)

**Campos:**
- `location` - Geometria PostGIS (POINT)
- `pinged_at` - Timestamp da localização
- `courier_id` - ID do entregador
- `delivery_id` - ID da entrega (opcional)

---

### Route
**Rota calculada para entrega**

**Responsabilidades:**
- Armazena dados de rota do Google Maps
- Distância, duração e polyline
- Cache de cálculos de rota

**Relacionamentos:**
- `belongs_to :delivery` - Entrega proprietária

---

### WebhookEndpoint
**Endpoints para notificações webhook**

**Responsabilidades:**
- URLs para receber notificações de eventos
- Configuração de eventos específicos
- Integração com sistemas externos

**Relacionamentos:**
- `belongs_to :account` - Conta proprietária

---

### Subscription
**Planos de assinatura**

**Responsabilidades:**
- Controla limites de uso por conta
- Gerencia período ativo da assinatura
- Define quotas de entregas e entregadores

**Relacionamentos:**
- `belongs_to :account` - Conta proprietária

## Concerns e Modules

### Trackable
**Funcionalidades de rastreamento**
- Gera tokens públicos únicos
- Métodos de tracking básico

### Geospatial
**Cálculos geoespaciais**
- Integração com PostGIS
- Cálculos de distância
- Manipulação de coordenadas

## Validações Globais

### Formato de Telefone
```ruby
/\A\+?[1-9]\d{1,14}\z/
```

### Coordenadas
- Latitude: -90 a 90
- Longitude: -180 a 180

### Status Enum Pattern
- Utiliza enums do Rails para status
- Valores inteiros no banco
- Métodos helper automáticos (created?, delivered?, etc.)

## Callbacks Padrão

### Geocodificação Automática
- Executa em background via jobs
- Dispara apenas quando endereço muda
- Skipável em ambiente de teste

### Broadcasting WebSocket
- Mudanças de status são brodcastadas automaticamente
- Clientes conectados recebem atualizações em tempo real

### Auditoria
- `has_paper_trail` em modelos críticos
- Rastreia mudanças para auditoria
