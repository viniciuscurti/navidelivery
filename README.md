# 🚚 NaviDelivery API

Sistema completo de gerenciamento e rastreamento de entregas desenvolvido em Ruby on Rails com arquitetura limpa, padrões modernos e foco em escalabilidade.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Tecnologias](#-tecnologias)
- [Funcionalidades](#-funcionalidades)
- [Instalação](#-instalação)
- [Configuração](#-configuração)
- [API Documentation](#-api-documentation)
- [Testes](#-testes)
- [Deployment](#-deployment)
- [Monitoramento](#-monitoramento)
- [Contribuição](#-contribuição)

## 🎯 Visão Geral

NaviDelivery é uma plataforma robusta para gestão de entregas que oferece:

### Características Principais
- **🔄 Rastreamento em Tempo Real** - WebSockets com ActionCable
- **📱 Multi-tenant** - Suporte a múltiplas contas/lojas
- **🗺️ Geolocalização Avançada** - PostGIS para cálculos geoespaciais
- **🚀 Processamento Assíncrono** - Sidekiq para jobs em background
- **🔐 Segurança Robusta** - Autenticação JWT, rate limiting, CORS
- **📊 API RESTful** - Endpoints bem documentados e versionados
- **🐳 Containerizado** - Docker para desenvolvimento e produção
- **🧪 Testes Abrangentes** - RSpec com coverage completo

### Casos de Uso
- Empresas de delivery de comida
- E-commerce com entrega própria
- Logistics e transportadoras
- Marketplace com múltiplos vendedores

## 🏗 Arquitetura

### Diagrama de Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │    Web Admin    │    │  External APIs  │
│                 │    │                 │    │                 │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Load Balancer │
                    │    (Nginx)      │
                    └─────────┬───────┘
                              │
                 ┌─────────────────────────┐
                 │     Rails API Server    │
                 │   (Puma + ActionCable)  │
                 └─────────┬───────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
 ┌────────▼───────┐ ┌──────▼──────┐ ┌───────▼────────┐
 │   PostgreSQL   │ │    Redis    │ │     Sidekiq    │
 │   + PostGIS    │ │   (Cache)   │ │  (Background)  │
 └────────────────┘ └─────────────┘ └────────────────┘
```

### Padrões Arquiteturais

- **Clean Architecture** - Separação em camadas bem definidas
- **Domain-Driven Design** - Modelagem focada no domínio de entregas
- **CQRS** - Separação entre comandos e consultas
- **Event-Driven** - Eventos para sincronização de estado
- **Multi-tenancy** - Isolamento por conta/organização

### Estrutura de Camadas

```
┌─────────────────────────────────────────────────────────┐
│                   Interface Layer                       │
│  Controllers, Serializers, Views, WebSockets           │
├─────────────────────────────────────────────────────────┤
│                 Application Layer                       │
│      Services, Interactors, Jobs, Policies             │
├─────────────────────────────────────────────────────────┤
│                   Domain Layer                          │
│     Models, Concerns, Value Objects, Entities          │
├─────────────────────────────────────────────────────────┤
│               Infrastructure Layer                      │
│   Repositories, External APIs, Database, Cache         │
└─────────────────────────────────────────────────────────┘
```

## 🛠 Tecnologias

### Backend Core
- **Ruby 3.3.6** - Linguagem principal
- **Rails 7.1.5** - Framework web
- **PostgreSQL 15** - Banco de dados principal
- **PostGIS 3.3** - Extensão geoespacial
- **Redis 7** - Cache e filas

### Processamento e Background
- **Sidekiq** - Jobs assíncronos
- **ActionCable** - WebSockets real-time
- **Puma** - Servidor de aplicação

### Autenticação e Autorização
- **Devise** - Autenticação de usuários
- **JWT** - Tokens para API
- **Pundit** - Autorização baseada em políticas

### Segurança
- **Rack::Attack** - Rate limiting e proteção DDoS
- **Rack::Cors** - Configuração CORS
- **bcrypt** - Hash de senhas
- **Security Headers** - Headers de segurança

### Desenvolvimento e Testes
- **RSpec** - Framework de testes
- **FactoryBot** - Fixtures para testes
- **Faker** - Dados fake para testes
- **VCR** - Gravação de requisições HTTP
- **Simplecov** - Coverage de código
- **Rubocop** - Linting e style guide

### Infraestrutura
- **Docker** - Containerização
- **Nginx** - Proxy reverso (produção)
- **Figaro** - Gerenciamento de variáveis

### Integrações Externas
- **HTTParty** - Cliente HTTP
- **WhatsApp API** - Notificações
- **Google Maps** - Geocoding e rotas (configurável)

## 🚀 Funcionalidades

### Core Features

#### 🏪 Gestão Multi-tenant
- **Contas separadas** para diferentes empresas
- **Lojas múltiplas** por conta
- **Usuários com permissões** granulares
- **Configurações isoladas** por tenant

#### 📦 Gestão de Entregas
- **CRUD completo** de entregas
- **Estados controlados** com transições validadas
- **Atribuição de entregadores** automática ou manual
- **Histórico completo** de mudanças

#### 🗺️ Geolocalização
- **Cálculo de distâncias** precisas
- **Coordenadas geográficas** com PostGIS
- **Rastreamento em tempo real** de entregadores
- **Geofencing** para detecção automática

#### 📱 Rastreamento Público
- **Links públicos** sem autenticação
- **Interface responsiva** para mobile
- **Atualizações em tempo real** via WebSocket
- **Estimativas de entrega** dinâmicas

#### 🔔 Notificações
- **WhatsApp** para clientes
- **WebSockets** para atualizações real-time
- **Webhooks** para sistemas externos
- **Email** para administradores

### API Endpoints

#### Autenticação
```
POST /auth/sign_in           # Login
POST /auth/sign_up           # Registro
DELETE /auth/sign_out        # Logout
```

#### Entregas
```
GET    /api/v1/deliveries              # Listar entregas
POST   /api/v1/deliveries              # Criar entrega
GET    /api/v1/deliveries/:id          # Detalhar entrega
PATCH  /api/v1/deliveries/:id          # Atualizar entrega
POST   /api/v1/deliveries/:id/assign   # Atribuir entregador
POST   /api/v1/deliveries/:id/pings    # Registrar localização
```

#### Rastreamento Público
```
GET /api/v1/deliveries/track/:token        # Dados da entrega
GET /api/v1/deliveries/track/:token/status # Status atual
```

#### Entregadores
```
GET  /api/v1/couriers              # Listar entregadores
GET  /api/v1/couriers/:id          # Detalhar entregador
POST /api/v1/couriers/:id/start_shift  # Iniciar turno
POST /api/v1/couriers/:id/end_shift    # Finalizar turno
```

#### Webhooks
```
POST   /api/v1/webhook_endpoints    # Criar webhook
PATCH  /api/v1/webhook_endpoints/:id # Atualizar webhook
DELETE /api/v1/webhook_endpoints/:id # Remover webhook
```

### Background Jobs

#### LocationPingCleanupJob
- **Execução**: Diária às 02:00
- **Função**: Limpar dados antigos de localização
- **Retenção**: 30 dias por padrão

#### DeliveryStatusNotificationJob
- **Trigger**: Mudanças de status
- **Função**: Enviar notificações via WhatsApp/Email
- **Retry**: 3 tentativas com backoff

#### RouteCalculationJob
- **Trigger**: Atribuição de entregador
- **Função**: Calcular rota otimizada
- **Timeout**: 30 segundos

#### GeofenceCheckJob
- **Execução**: A cada ping de localização
- **Função**: Verificar entrada/saída de zonas
- **Performance**: < 100ms

## 📥 Instalação

### Pré-requisitos
- **Docker** e **Docker Compose**
- **Git**
- **Ruby 3.3.6** (se executar localmente)

### Com Docker (Recomendado)

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/navidelivery.git
cd navidelivery

# 2. Construa e execute os containers
docker-compose up -d

# 3. Execute as migrations
docker-compose exec web rails db:create db:migrate

# 4. Execute os seeds (opcional)
docker-compose exec web rails db:seed

# 5. Acesse a aplicação
open http://localhost:3000
```

### Instalação Local

```bash
# 1. Clone e instale dependências
git clone https://github.com/seu-usuario/navidelivery.git
cd navidelivery
bundle install

# 2. Configure o banco de dados
cp config/database.yml.example config/database.yml
# Edite as configurações conforme necessário

# 3. Configure variáveis de ambiente
cp config/application.yml.example config/application.yml

# 4. Execute migrations
rails db:create db:migrate db:seed

# 5. Inicie os serviços
rails server                    # Terminal 1
bundle exec sidekiq            # Terminal 2
```

## ⚙️ Configuração

### Variáveis de Ambiente

Copie e configure o arquivo de variáveis:

```bash
cp config/application.yml.example config/application.yml
```

#### Configurações Essenciais

```yaml
# config/application.yml
development:
  # Database
  DATABASE_URL: "postgresql://postgres:postgres@localhost:5432/navidelivery_development"
  
  # Redis
  REDIS_URL: "redis://localhost:6379/1"
  
  # JWT
  JWT_SECRET_KEY: "seu-jwt-secret-muito-seguro"
  
  # WhatsApp (opcional)
  WHATSAPP_TOKEN: "seu-token-whatsapp"
  WHATSAPP_PHONE_NUMBER_ID: "seu-phone-number-id"
  
  # Maps (opcional)
  GOOGLE_MAPS_API_KEY: "sua-api-key-google-maps"
  
  # Email (opcional)
  SMTP_ADDRESS: "smtp.gmail.com"
  SMTP_USERNAME: "seu-email@gmail.com"
  SMTP_PASSWORD: "sua-senha-app"
```

### Configuração do Banco

```bash
# Development
rails db:create
rails db:migrate
rails db:seed

# Test
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate

# Production
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
```

### Configuração do Sidekiq

```yaml
# config/sidekiq.yml
:concurrency: 5
:queues:
  - critical
  - default
  - low

:scheduler:
  location_ping_cleanup:
    cron: '0 2 * * *'
    class: LocationPingCleanupJob
```

## 📚 API Documentation

### Swagger/OpenAPI

A documentação completa da API está disponível em:

- **Desenvolvimento**: `http://localhost:3000/api-docs`
- **Produção**: `https://sua-api.com/api-docs`

### Autenticação

A API utiliza **JWT tokens** para autenticação:

```bash
# 1. Fazer login
curl -X POST http://localhost:3000/auth/sign_in \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password"}'

# 2. Usar o token retornado
curl -X GET http://localhost:3000/api/v1/deliveries \
  -H "Authorization: Bearer SEU_JWT_TOKEN"
```

### Rate Limiting

```ruby
# Limites por IP
# - 5 requests/minute para login
# - 100 requests/minute para API geral
# - 300 requests/minute para tracking público
```

### Formato de Resposta

```json
{
  "data": {
    "id": "123",
    "type": "delivery",
    "attributes": {
      "status": "en_route",
      "pickup_address": "Rua A, 123",
      "dropoff_address": "Rua B, 456",
      "created_at": "2025-09-08T10:00:00Z"
    },
    "relationships": {
      "courier": {
        "data": { "id": "456", "type": "courier" }
      }
    }
  },
  "included": [
    {
      "id": "456",
      "type": "courier",
      "attributes": {
        "name": "João Silva",
        "phone": "+5511999999999"
      }
    }
  ]
}
```

## 🧪 Testes

### Executar Testes

```bash
# Todos os testes
bundle exec rspec

# Testes específicos
bundle exec rspec spec/models/
bundle exec rspec spec/services/delivery_status_service_spec.rb

# Com coverage
bundle exec rspec --format documentation

# Performance tests
bundle exec rspec --tag performance
```

### Coverage

```bash
# Gerar relatório de coverage
open coverage/index.html
```

### Estrutura de Testes

```
spec/
├── controllers/      # Testes de controllers
├── models/          # Testes de models
├── services/        # Testes de services
├── jobs/           # Testes de background jobs
├── requests/       # Testes de integração API
├── system/         # Testes end-to-end
└── factories.rb    # Factories para testes
```

### Exemplo de Teste

```ruby
# spec/services/delivery_status_service_spec.rb
RSpec.describe DeliveryStatusService do
  let(:delivery) { create(:delivery, status: 'created') }

  describe '#call' do
    context 'when transition is valid' do
      it 'updates delivery status' do
        result = described_class.call(
          delivery: delivery,
          status: 'assigned'
        )

        expect(result).to be_success
        expect(delivery.reload.status).to eq 'assigned'
      end
    end
  end
end
```

## 🚀 Deployment

### Docker Production

```bash
# 1. Build da imagem de produção
docker build -f Dockerfile.prod -t navidelivery:latest .

# 2. Deploy com docker-compose
docker-compose -f docker-compose.prod.yml up -d

# 3. Execute migrations
docker-compose -f docker-compose.prod.yml exec web rails db:migrate
```

### Variáveis de Produção

```yaml
# config/application.yml (production)
production:
  DATABASE_URL: <%= ENV['DATABASE_URL'] %>
  REDIS_URL: <%= ENV['REDIS_URL'] %>
  SECRET_KEY_BASE: <%= ENV['SECRET_KEY_BASE'] %>
  JWT_SECRET_KEY: <%= ENV['JWT_SECRET_KEY'] %>
  RAILS_MAX_THREADS: <%= ENV['RAILS_MAX_THREADS'] || 5 %>
```

### Health Checks

```bash
# Verificar saúde da aplicação
curl http://localhost:3000/health

# Resposta esperada
{
  "status": "ok",
  "database": "ok",
  "redis": "ok",
  "sidekiq": "ok"
}
```

## 📊 Monitoramento

### Métricas Disponíveis

- **Performance**: Tempo de resposta, throughput
- **Errors**: Rate de erro, exceções capturadas
- **Business**: Entregas por hora, tempo médio de entrega
- **Infrastructure**: CPU, memória, disco

### Dashboards

- **Sidekiq Web**: `/sidekiq` (development)
- **Rails Console**: Análise de dados
- **Logs**: Estruturados em JSON

### Alertas Recomendados

- Taxa de erro > 5%
- Tempo de resposta > 2s
- Queue de jobs > 1000
- Uso de CPU > 80%

## 🤝 Contribuição

### Processo de Contribuição

1. **Fork** o projeto
2. **Crie uma branch** para sua feature (`git checkout -b feature/amazing-feature`)
3. **Commit** suas mudanças (`git commit -m 'Add some amazing feature'`)
4. **Push** para a branch (`git push origin feature/amazing-feature`)
5. **Abra um Pull Request**

### Guidelines

- Siga o **style guide** do Rubocop
- **Testes** são obrigatórios para novas features
- **Documentação** deve ser atualizada
- **Commits** devem seguir conventional commits

### Configuração para Desenvolvimento

```bash
# Setup hooks
cp scripts/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# Instalar dependências de desenvolvimento
bundle install --with development test

# Executar linting
bundle exec rubocop
bundle exec rubocop --auto-correct
```

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📞 Suporte

- **Issues**: [GitHub Issues](https://github.com/seu-usuario/navidelivery/issues)
- **Documentação**: [Wiki do Projeto](https://github.com/seu-usuario/navidelivery/wiki)
- **Email**: suporte@navidelivery.com

---

**Desenvolvido com ❤️ pela equipe NaviDelivery**
