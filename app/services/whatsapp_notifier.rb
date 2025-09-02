class WhatsappNotifier
  # Estratégia 1 (oficial): WhatsApp Cloud API (Meta)
  # Requer:
  # - ENV['WHATSAPP_TOKEN']           (Bearer)
  # - ENV['WHATSAPP_PHONE_NUMBER_ID'] (ID do número no WABA)
  #
  # Estratégia 2 (não-oficial / gratuita): CallMeBot
  # - ENV['CALLMEBOT_PHONE']          (msisdn com DDI, ex: 5511999999999)
  # - ENV['CALLMEBOT_API_KEY']
  #
  # Em produção, prefira Meta Cloud API (1000 conversas de serviço/mês gratuitas).

  META_ENDPOINT = ->(phone_number_id) { "https://graph.facebook.com/v17.0/#{phone_number_id}/messages" }.freeze

  def self.send_tracking_link(phone_e164, tracking_url, customer_name: nil)
    return false if phone_e164.blank? || tracking_url.blank?

    if ENV['WHATSAPP_TOKEN'].present? && ENV['WHATSAPP_PHONE_NUMBER_ID'].present?
      return send_via_meta_cloud_api(phone_e164, tracking_url, customer_name: customer_name)
    end

    if ENV['CALLMEBOT_API_KEY'].present? && ENV['CALLMEBOT_PHONE'].present?
      return send_via_callmebot(phone_e164, tracking_url, customer_name: customer_name)
    end

    Rails.logger.info "[WhatsappNotifier] Nenhum provedor configurado. Link: #{tracking_url} para #{phone_e164}"
    false
  end

  def self.send_via_meta_cloud_api(phone_e164, tracking_url, customer_name: nil)
    token = ENV['WHATSAPP_TOKEN']
    phone_number_id = ENV['WHATSAPP_PHONE_NUMBER_ID']
    url = META_ENDPOINT.call(phone_number_id)

    body = {
      messaging_product: 'whatsapp',
      to: phone_e164,
      type: 'text',
      text: {
        preview_url: true,
        body: customer_name.present? ? "Olá #{customer_name}, acompanhe sua entrega em tempo real: #{tracking_url}" : "Acompanhe sua entrega em tempo real: #{tracking_url}"
      }
    }

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{token}"
    }

    resp = HTTParty.post(url, body: body.to_json, headers: headers, timeout: 10)
    if resp.code.between?(200, 299)
      Rails.logger.info "[WhatsappNotifier] Enviado via Meta Cloud API para #{phone_e164}"
      true
    else
      Rails.logger.warn "[WhatsappNotifier] Falha Meta Cloud API (#{resp.code}): #{resp.body}"
      false
    end
  rescue => e
    Rails.logger.error "[WhatsappNotifier] Erro Meta Cloud API: #{e.class} #{e.message}"
    false
  end

  def self.send_via_callmebot(phone_e164, tracking_url, customer_name: nil)
    # CallMeBot usa um número aprovado no serviço para encaminhar mensagens (não-oficial)
    to = phone_e164.gsub(/\D/, '')
    text = customer_name.present? ? "Ola #{customer_name}, acompanhe sua entrega: #{tracking_url}" : "Acompanhe sua entrega: #{tracking_url}"
    url = "https://api.callmebot.com/whatsapp.php?phone=#{to}&text=#{ERB::Util.url_encode(text)}&apikey=#{ENV['CALLMEBOT_API_KEY']}"

    resp = HTTParty.get(url, timeout: 10)
    if resp.code.between?(200, 299)
      Rails.logger.info "[WhatsappNotifier] Enviado via CallMeBot para #{phone_e164}"
      true
    else
      Rails.logger.warn "[WhatsappNotifier] Falha CallMeBot (#{resp.code}): #{resp.body}"
      false
    end
  rescue => e
    Rails.logger.error "[WhatsappNotifier] Erro CallMeBot: #{e.class} #{e.message}"
    false
  end
end
