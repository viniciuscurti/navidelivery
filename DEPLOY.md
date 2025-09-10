# NaviDelivery - Deploy Guide

## Pré-requisitos
- Docker e Docker Compose
- PostgreSQL com extensão PostGIS
- Redis
- Variáveis de ambiente configuradas

## Variáveis de Ambiente Obrigatórias

```bash
# Database
DATABASE_URL=postgresql://user:password@host:5432/navidelivery_production

# Redis
REDIS_URL=redis://host:6379/1

# Security
SECRET_KEY_BASE=your_secret_key_base
JWT_SECRET=your_jwt_secret
RAILS_MASTER_KEY=your_master_key

# External APIs
MAPS_API_KEY=your_google_maps_api_key
WHATSAPP_API_URL=https://api.whatsapp.business/v1
WHATSAPP_API_TOKEN=your_whatsapp_token

# Application
FRONTEND_URL=https://your-frontend-domain.com
DEFAULT_FROM_EMAIL=noreply@your-domain.com
WEBHOOK_SECRET=your_webhook_secret

# Performance
SIDEKIQ_CONCURRENCY=10
RAILS_MAX_THREADS=5
```

## Deploy Steps

### 1. Build da aplicação
```bash
docker-compose -f docker-compose.prod.yml build
```

### 2. Executar migrações
```bash
docker-compose -f docker-compose.prod.yml run --rm web rails db:create db:migrate
```

### 3. Precompile assets
```bash
docker-compose -f docker-compose.prod.yml run --rm web rails assets:precompile
```

### 4. Iniciar serviços
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Health Checks

### Application Health
```bash
curl https://your-domain.com/health
```

### Database Health
```bash
docker-compose exec web rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').first"
```

### Redis Health
```bash
docker-compose exec redis redis-cli ping
```

## Monitoring

### Logs
```bash
# Application logs
docker-compose logs -f web

# Sidekiq logs
docker-compose logs -f sidekiq

# Database logs
docker-compose logs -f db
```

### Metrics
- Sidekiq Web UI: `/sidekiq` (development only)
- Health endpoint: `/health`
- API logs no formato JSON estruturado

## Backup

### Database Backup
```bash
docker-compose exec db pg_dump -U postgres navidelivery_production > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database
```bash
docker-compose exec -T db psql -U postgres navidelivery_production < backup_file.sql
```

## Security Checklist

- ✅ SSL/TLS habilitado
- ✅ Rate limiting configurado
- ✅ CORS apropriadamente configurado
- ✅ Headers de segurança
- ✅ Secrets em variáveis de ambiente
- ✅ Database com SSL
- ✅ Redis com autenticação

## Performance Tuning

### Database
- Índices apropriados para geolocalização
- Connection pooling configurado
- Query optimization com explain

### Redis
- Configuração de memória apropriada
- Persistência configurada

### Sidekiq
- Número de workers baseado em CPU
- Queues prioritárias
- Dead job cleanup
