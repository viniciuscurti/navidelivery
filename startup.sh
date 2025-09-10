#!/bin/bash

# 🚀 Script para subir a aplicação NaviDelivery localmente
# Este script automatiza todo o processo de setup

echo "🚀 Iniciando setup da aplicação NaviDelivery..."

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker Desktop e tente novamente."
    exit 1
fi

echo "✅ Docker está rodando"

# Parar containers existentes se houver
echo "🛑 Parando containers existentes..."
docker-compose down

# Limpar volumes órfãos se necessário
echo "🧹 Limpando volumes órfãos..."
docker-compose down --volumes --remove-orphans

# Construir imagens
echo "🏗️ Construindo imagens Docker..."
docker-compose build --no-cache

# Subir banco e Redis primeiro
echo "🗄️ Iniciando banco PostgreSQL e Redis..."
docker-compose up -d db redis

# Aguardar banco ficar pronto
echo "⏳ Aguardando banco PostgreSQL ficar pronto..."
for i in {1..30}; do
    if docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
        echo "✅ PostgreSQL está pronto!"
        break
    fi
    echo "   Tentativa $i/30..."
    sleep 2
done

# Aguardar Redis ficar pronto
echo "⏳ Aguardando Redis ficar pronto..."
for i in {1..10}; do
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        echo "✅ Redis está pronto!"
        break
    fi
    echo "   Tentativa $i/10..."
    sleep 1
done

# Instalar gems
echo "💎 Instalando gems..."
docker-compose run --rm web bundle install

# Executar migrações
echo "🗄️ Executando migrações do banco..."
docker-compose run --rm web bundle exec rails db:create
docker-compose run --rm web bundle exec rails db:migrate
docker-compose run --rm web bundle exec rails db:seed

# Subir aplicação completa
echo "🚀 Subindo aplicação completa..."
docker-compose up -d

# Aguardar aplicação ficar pronta
echo "⏳ Aguardando aplicação ficar pronta..."
for i in {1..30}; do
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ Aplicação está rodando!"
        break
    fi
    echo "   Tentativa $i/30..."
    sleep 3
done

echo ""
echo "🎉 APLICAÇÃO ESTÁ RODANDO!"
echo ""
echo "📋 Informações importantes:"
echo "   🌐 Aplicação: http://localhost:3000"
echo "   🗄️ PostgreSQL: localhost:5432"
echo "   🔴 Redis: localhost:6379"
echo "   📊 Sidekiq UI: http://localhost:3000/sidekiq"
echo ""
echo "🧪 Para testar o tracking em tempo real:"
echo "   1. Acesse o console: docker-compose exec web bundle exec rails console"
echo "   2. Execute o simulador do motoboy (ver instruções abaixo)"
echo ""
echo "📱 Comandos úteis:"
echo "   Ver logs: docker-compose logs -f"
echo "   Console Rails: docker-compose exec web bundle exec rails console"
echo "   Bash no container: docker-compose exec web bash"
echo "   Parar tudo: docker-compose down"
echo ""
echo "✅ Setup completo!"
