class HomeController < ApplicationController
  # Landing page pública - sem autenticação necessária
  skip_before_action :authenticate_user!, only: [:index]

  def index
    # Métricas em tempo real para social proof
    @stats = {
      total_deliveries: delivery_count,
      active_couriers: courier_count,
      partner_stores: store_count,
      cities_served: cities_count
    }

    # Planos de preços
    @pricing_plans = pricing_plans_data

    # Depoimentos de clientes
    @testimonials = testimonials_data

    # Features principais
    @features = features_data
  end

  def demo
    # Página de demonstração do produto
    render 'demo'
  end

  def pricing
    @pricing_plans = pricing_plans_data
    render 'pricing'
  end

  def contact
    # Página de contato
    render 'contact'
  end

  def about
    # Sobre a empresa
    render 'about'
  end

  private

  def delivery_count
    Rails.cache.fetch('home_stats_deliveries', expires_in: 1.hour) do
      Delivery.count
    end
  end

  def courier_count
    Rails.cache.fetch('home_stats_couriers', expires_in: 1.hour) do
      Courier.where(status: :available).count
    end
  end

  def store_count
    Rails.cache.fetch('home_stats_stores', expires_in: 1.hour) do
      Store.count
    end
  end

  def cities_count
    # Simular cidades atendidas - implementar com dados reais
    12
  end

  def pricing_plans_data
    [
      {
        name: 'Starter',
        price: 'R$ 99',
        period: '/mês',
        description: 'Perfeito para pequenos negócios',
        features: [
          'Até 100 entregas/mês',
          'Rastreamento em tempo real',
          'Notificações WhatsApp',
          'Dashboard básico',
          'Suporte por email'
        ],
        cta: 'Começar Agora',
        popular: false
      },
      {
        name: 'Professional',
        price: 'R$ 299',
        period: '/mês',
        description: 'Para empresas em crescimento',
        features: [
          'Até 1.000 entregas/mês',
          'Múltiplos entregadores',
          'API completa',
          'Relatórios avançados',
          'Webhooks personalizados',
          'Suporte prioritário'
        ],
        cta: 'Teste Grátis',
        popular: true
      },
      {
        name: 'Enterprise',
        price: 'Sob consulta',
        period: '',
        description: 'Soluções customizadas',
        features: [
          'Entregas ilimitadas',
          'White-label',
          'Integração personalizada',
          'SLA garantido',
          'Suporte 24/7',
          'Gerente dedicado'
        ],
        cta: 'Falar com Vendas',
        popular: false
      }
    ]
  end

  def testimonials_data
    [
      {
        name: 'Carlos Silva',
        company: 'Pizza Express',
        role: 'CEO',
        avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        text: 'O NaviDelivery transformou nossa operação. Reduzimos o tempo de entrega em 40% e nossos clientes adoram o rastreamento em tempo real.'
      },
      {
        name: 'Maria Santos',
        company: 'Farmácia Vida',
        role: 'Gerente de Operações',
        avatar: 'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=150&h=150&fit=crop&crop=face',
        text: 'A facilidade de integração e a confiabilidade do sistema nos permitiu focar no que realmente importa: atender bem nossos clientes.'
      },
      {
        name: 'João Oliveira',
        company: 'SuperMercado Digital',
        role: 'Diretor de Logística',
        avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        text: 'Com 500+ entregas diárias, precisávamos de uma solução robusta. O NaviDelivery superou todas as expectativas.'
      }
    ]
  end

  def features_data
    [
      {
        icon: '🚚',
        title: 'Rastreamento em Tempo Real',
        description: 'Acompanhe suas entregas em tempo real com atualizações automáticas via WhatsApp.'
      },
      {
        icon: '📱',
        title: 'Multi-plataforma',
        description: 'API completa para integração com qualquer sistema, app mobile e dashboard web.'
      },
      {
        icon: '🗺️',
        title: 'Otimização de Rotas',
        description: 'Algoritmos inteligentes para otimizar rotas e reduzir custos de entrega.'
      },
      {
        icon: '📊',
        title: 'Analytics Avançado',
        description: 'Relatórios detalhados sobre performance, custos e satisfação do cliente.'
      },
      {
        icon: '🔐',
        title: 'Segurança Enterprise',
        description: 'Criptografia de ponta a ponta e compliance com LGPD.'
      },
      {
        icon: '⚡',
        title: 'Alta Performance',
        description: 'Infraestrutura em nuvem com 99.9% de uptime garantido.'
      }
    ]
  end
end

