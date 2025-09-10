#!/bin/bash

echo "🚀 Iniciando NaviDelivery com Docker..."

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down

# Remover volumes órfãos (opcional)
# docker-compose down -v

# Build das imagens (necessário após mudanças no Dockerfile)
echo "🔨 Fazendo build das imagens..."
docker-compose build

# Subir containers
echo "📦 Subindo containers..."
docker-compose up -d db redis

# Aguardar serviços subirem
echo "⏳ Aguardando PostgreSQL e Redis..."
sleep 10

# Subir aplicação Rails
echo "🚀 Subindo aplicação Rails..."
docker-compose up web

echo "✅ NaviDelivery rodando em: http://localhost:3000"
