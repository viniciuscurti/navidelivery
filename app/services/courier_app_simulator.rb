# frozen_string_literal: true

# Exemplo de como o APP DO MOTOBOY enviaria atualizações de localização
class CourierAppSimulator
  def initialize(delivery_token)
    @delivery_token = delivery_token
    @api_base = 'http://localhost:3000/api/v1/public'
  end

  # Simular motoboy enviando localização a cada 10 segundos
  def start_tracking_simulation
    puts "🏍️ Iniciando simulação do app do motoboy..."
    puts "📱 Token da entrega: #{@delivery_token}"

    # Rota simulada: Av. Paulista -> Rua Augusta (São Paulo)
    route_points = [
      { lat: -23.5505, lng: -46.6333, location: "Av. Paulista, 1000" },
      { lat: -23.5510, lng: -46.6340, location: "Av. Paulista, 1200" },
      { lat: -23.5515, lng: -46.6350, location: "Av. Paulista, 1400" },
      { lat: -23.5520, lng: -46.6360, location: "Cruzamento com Rua Augusta" },
      { lat: -23.5525, lng: -46.6370, location: "Rua Augusta, 100" },
      { lat: -23.5530, lng: -46.6380, location: "Rua Augusta, 300" },
      { lat: -23.5535, lng: -46.6390, location: "Rua Augusta, 500 - DESTINO!" }
    ]

    route_points.each_with_index do |point, index|
      puts "\n📍 Passo #{index + 1}/#{route_points.length}"
      puts "   Localização: #{point[:location]}"
      puts "   Coordenadas: #{point[:lat]}, #{point[:lng]}"

      # Enviar atualização para o servidor
      response = send_location_update(point[:lat], point[:lng])

      if response[:success]
        puts "   ✅ Localização atualizada com sucesso!"
        puts "   ⏰ ETA atual: #{response[:eta]}"
        puts "   📊 Progresso: #{response[:progress]}%"
      else
        puts "   ❌ Erro ao atualizar localização"
      end

      # Aguardar 10 segundos (simular movimento real)
      sleep(10) unless Rails.env.test?
    end

    puts "\n🎉 Simulação concluída! O cliente viu tudo em tempo real no mapa!"
  end

  private

  def send_location_update(latitude, longitude)
    # Simular requisição HTTP que o app do motoboy faria
    puts "   📡 Enviando: POST #{@api_base}/track/#{@delivery_token}/location"

    # Em um app real, seria algo como:
    # HTTParty.post("#{@api_base}/track/#{@delivery_token}/location", {
    #   body: { latitude: latitude, longitude: longitude }.to_json,
    #   headers: { 'Content-Type' => 'application/json' }
    # })

    # Para simulação, vamos usar o método direto do Rails
    delivery = Delivery.find_by(public_token: @delivery_token)
    if delivery
      tracking_service = RealTimeTrackingService.new(delivery)
      tracking_service.update_courier_location(latitude, longitude)
      estimates = tracking_service.real_time_estimates

      {
        success: true,
        eta: estimates&.dig(:current_eta),
        progress: tracking_service.delivery_progress
      }
    else
      { success: false, error: 'Entrega não encontrada' }
    end
  end
end

# Exemplo de uso no console Rails:
#
# # 1. Criar uma entrega
# delivery = Delivery.first
#
# # 2. Simular app do motoboy
# simulator = CourierAppSimulator.new(delivery.public_token)
# simulator.start_tracking_simulation
#
# # 3. Cliente vê no navegador: http://localhost:3000/track/TOKEN_DA_ENTREGA
