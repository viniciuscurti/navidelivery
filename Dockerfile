# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.3.6

# Stage de build (instala dependências de compilação)
FROM ruby:${RUBY_VERSION}-alpine AS build

# Variável para controlar precompilação de assets (passar --build-arg PRECOMPILE_ASSETS=true em produção)
ARG PRECOMPILE_ASSETS=false
ENV RAILS_ENV=production \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# Dependências de build (postgresql-dev, vips-dev, geos-dev, proj-dev para rgeo/postgis)
RUN apk add --no-cache build-base git postgresql-dev vips-dev geos-dev proj-dev tzdata \
  && gem update --system --no-document

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install --no-cache

# Copia código
COPY . .

# Precompile bootsnap
RUN bundle exec bootsnap precompile app/ lib/ || true

# Precompile assets opcional (evita quebrar build em dev)
RUN if [ "$PRECOMPILE_ASSETS" = "true" ]; then \
    DISABLE_DB=1 SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile; \
  fi

# Stage runtime enxuto
FROM ruby:${RUBY_VERSION}-alpine AS runtime
ENV RAILS_ENV=production \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development test" \
    TZ=UTC

# Dependências runtime (sem -dev)
RUN apk add --no-cache postgresql-client vips geos proj tzdata bash libstdc++ \
  && adduser -D -h /rails rails

WORKDIR /rails

# Copia gems e app do stage build
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Permissões
RUN chown -R rails:rails /rails
USER rails

EXPOSE 3000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
