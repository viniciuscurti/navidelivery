FROM ruby:3.3.6-alpine

# Instalação de dependências essenciais
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    tzdata \
    bash \
    vips-dev \
    geos-dev \
    proj-dev \
    netcat-openbsd

# Configuração do ambiente
ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4

WORKDIR /app

# Copiar Gemfile primeiro para aproveitar cache do Docker
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copiar resto da aplicação
COPY . .

# Script de entrada para desenvolvimento
COPY bin/docker-entrypoint /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
ENTRYPOINT ["docker-entrypoint"]
