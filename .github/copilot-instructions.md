# Copilot Instructions para Projeto Ruby on Rails

## Objetivo
Este projeto é uma API Ruby on Rails para entrega de produtos, integrando serviços como Sidekiq (jobs assíncronos), PostgreSQL (banco de dados), Redis (filas/cache) e Docker (orquestração). O frontend é desacoplado e consome a API via REST. O Copilot deve atuar como especialista em Rails, priorizando boas práticas, segurança, testes automatizados e integração com Docker.

## Contexto do Produto
- API para gestão e entrega de produtos.
- Integração com serviços externos e processamento assíncrono.
- Foco em escalabilidade, segurança e manutenibilidade.
- Frontend desacoplado, comunicação via REST.

## Arquitetura e Padrões

- **Arquitetura Limpa (Clean Architecture):** Separação entre camadas (Controllers, Services, Models, Repositories).
- **RESTful API:** Endpoints seguem convenções REST.
- **Domain-Driven Design (DDD):** Modelagem centrada no domínio de entregas.
- **Service Objects:** Lógica de negócio fora dos controllers.
- **Background Jobs:** Sidekiq para tarefas assíncronas.
- **Testes Automatizados:** RSpec e FactoryBot.
- **Configuração por Ambiente:** YAML e variáveis de ambiente.
- **Segurança:** Autenticação JWT, proteção CSRF, validação de parâmetros.
- **Docker:** Containers para app, banco, Redis e Sidekiq.
- **CI/CD:** Integração contínua sugerida via GitHub Actions.
- **Padrões Rails:** Convenções, SOLID, DRY, migrations, middlewares, versionamento de API (`/api/v1/`), documentação Swagger/OpenAPI.

## Documentação Base

- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [API Ruby on Rails](https://api.rubyonrails.org/)
- [Bundler](https://bundler.io/docs.html)
