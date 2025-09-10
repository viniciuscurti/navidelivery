# 🚀 Guia Completo para Testar o Sistema de Tracking

## 📋 Pré-requisitos
- Docker Desktop instalado e rodando
- Porta 3000, 5432 e 6379 livres

## 🚀 Como Subir a Aplicação

### Opção 1: Script Automático (Recomendado)
```bash
cd /Users/vinicius.cd.lima/RubymineProjects/navidelivery
./startup.sh
```

### Opção 2: Passo a Passo Manual
```bash
# 1. Parar containers existentes
docker-compose down --volumes --remove-orphans

# 2. Construir imagens
docker-compose build --no-cache

# 3. Subir banco e Redis
docker-compose up -d db redis

# 4. Aguardar serviços ficarem prontos (30s)
sleep 30

# 5. Instalar gems
docker-compose run --rm web bundle install

# 6. Criar e migrar banco
docker-compose run --rm web bundle exec rails db:create
docker-compose run --rm web bundle exec rails db:migrate
docker-compose run --rm web bundle exec rails db:seed

# 7. Subir aplicação completa
docker-compose up -d

# 8. Ver logs
docker-compose logs -f web
```

## ✅ Verificar se está funcionando

### 1. Health Check
```bash
curl http://localhost:3000/health
# Deve retornar: {"status":"ok"}
```

### 2. Acessar aplicação
- 🌐 App: http://localhost:3000
- 📊 Sidekiq: http://localhost:3000/sidekiq

## 🧪 Testar Tracking em Tempo Real

### 1. Acessar Console Rails
```bash
docker-compose exec web bundle exec rails console
```

### 2. No Console, Execute:
```ruby
# Buscar a entrega de teste
delivery = Delivery.find_by(external_order_code: 'DEMO001')
puts "📦 Entrega: #{delivery.external_order_code}"
puts "🔗 Link de tracking: http://localhost:3000/track/#{delivery.public_token}"

# Copie o link e abra em uma aba do navegador
# Você verá o mapa com a rota completa
```

### 3. Simular Movimento do Motoboy:
```ruby
# No console Rails, execute:
simulator = CourierAppSimulator.new(delivery.public_token)
simulator.start_tracking_simulation

# Isso simulará o motoboy se movendo por 7 pontos diferentes
# Você verá em tempo real no navegador:
# - Marcador do motoboy se movendo no mapa
# - ETA sendo atualizado
# - Progresso aumentando
# - Timeline sendo atualizada
```

## 🎬 O que você verá no teste:

### No Console Rails:
```
🏍️ Iniciando simulação do app do motoboy...
📱 Token da entrega: abc123def456...

📍 Passo 1/7
   Localização: Av. Paulista, 1000
   📡 Enviando: POST http://localhost:3000/api/v1/public/track/TOKEN/location
   ✅ Localização atualizada com sucesso!
   ⏰ ETA atual: 12 minutos
   📊 Progresso: 15%

📍 Passo 2/7
   Localização: Av. Paulista, 1200
   ✅ Localização atualizada com sucesso!
   ⏰ ETA atual: 10 minutos
   📊 Progresso: 30%
...
```

### No Navegador (Página de Tracking):
- 🗺️ **Mapa interativo** com rota completa
- 🏍️ **Marcador laranja** do motoboy se movendo suavemente
- ⏰ **ETA dinâmico**: "Chegará em 10 minutos" → "8 minutos" → "5 minutos"
- 📊 **Barra de progresso**: 15% → 30% → 50% → 75% → 100%
- 📋 **Timeline**: Status sendo atualizado em tempo real
- 🔔 **Notificações**: "Seu entregador está chegando!"

## 🔧 Comandos Úteis

### Ver logs em tempo real:
```bash
docker-compose logs -f web
```

### Acessar container:
```bash
docker-compose exec web bash
```

### Reiniciar apenas a aplicação:
```bash
docker-compose restart web
```

### Parar tudo:
```bash
docker-compose down
```

### Limpar volumes (reset completo):
```bash
docker-compose down --volumes
```

## 🐛 Solução de Problemas Comuns

### Erro: "Port already in use"
```bash
# Parar todos os containers
docker-compose down
# Verificar portas em uso
lsof -i :3000
lsof -i :5432
lsof -i :6379
# Matar processos se necessário
```

### Erro: "Database does not exist"
```bash
docker-compose run --rm web bundle exec rails db:create
docker-compose run --rm web bundle exec rails db:migrate
```

### Erro: "Bundle not found"
```bash
docker-compose run --rm web bundle install
```

### Container não sobe:
```bash
# Rebuild completo
docker-compose down --volumes
docker-compose build --no-cache
docker-compose up -d
```

### Erro: "Google Maps API key"
```bash
# Verificar se a chave está no docker-compose.yml
grep GOOGLE_MAPS_API_KEY docker-compose.yml
```

## 📱 Teste com múltiplos clientes

1. **Abra várias abas** com o mesmo link de tracking
2. **Execute o simulador** no console
3. **Todas as abas** receberão atualizações em tempo real simultaneamente!

## 🎯 APIs para Integração

### Atualizar localização (para app do motoboy):
```bash
curl -X POST http://localhost:3000/api/v1/public/track/TOKEN/location \
  -H "Content-Type: application/json" \
  -d '{"latitude": -23.5505, "longitude": -46.6333}'
```

### Buscar dados de tracking:
```bash
curl http://localhost:3000/api/v1/public/track/TOKEN
```

## ✅ Tudo Funcionando?

Se você conseguir:
1. ✅ Acessar http://localhost:3000/health
2. ✅ Ver o mapa no link de tracking
3. ✅ Executar o simulador e ver movimento em tempo real
4. ✅ Ver ETA e progresso sendo atualizados

**🎉 PARABÉNS! O sistema está 100% funcional!**
