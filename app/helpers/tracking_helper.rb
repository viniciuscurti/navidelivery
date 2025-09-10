# frozen_string_literal: true

module TrackingHelper
  # Gerar link público de tracking para uma entrega
  def tracking_link(delivery)
    base_url = Rails.application.config.frontend_url || request.base_url
    "#{base_url}/track/#{delivery.public_token}"
  end

  # Gerar link da API de tracking
  def api_tracking_link(delivery)
    api_v1_public_track_url(token: delivery.public_token)
  end

  # Gerar QR Code para o link de tracking
  def tracking_qr_code(delivery)
    require 'rqrcode'

    link = tracking_link(delivery)
    qr = RQRCode::QRCode.new(link)

    # Retorna SVG do QR Code
    qr.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 6,
      standalone: true
    )
  end

  # Status de tracking em português
  def tracking_status_pt(status)
    case status.to_s
    when 'created' then 'Pedido Criado'
    when 'assigned' then 'Entregador Designado'
    when 'picked_up' then 'Coletado na Loja'
    when 'en_route' then 'A Caminho'
    when 'arriving' then 'Chegando'
    when 'delivered' then 'Entregue'
    when 'cancelled' then 'Cancelado'
    else status.humanize
    end
  end

  # Cor do status para UI
  def tracking_status_color(status)
    case status.to_s
    when 'created' then '#6B7280'      # Gray
    when 'assigned' then '#3B82F6'     # Blue
    when 'picked_up' then '#F59E0B'    # Yellow
    when 'en_route' then '#8B5CF6'     # Purple
    when 'arriving' then '#10B981'     # Green
    when 'delivered' then '#059669'    # Dark Green
    when 'cancelled' then '#EF4444'    # Red
    else '#6B7280'
    end
  end

  # Formatar ETA para exibição
  def format_eta(eta_data)
    return 'Calculando...' unless eta_data

    if eta_data[:duration_in_traffic]
      "#{eta_data[:duration_in_traffic]['text']} (com trânsito)"
    elsif eta_data[:duration]
      eta_data[:duration]['text']
    else
      'Indisponível'
    end
  end
end
