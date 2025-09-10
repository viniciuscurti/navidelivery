# frozen_string_literal: true

class CourierAppSimulatorInteractor < BaseInteractor
  def call
    require_params!(:delivery_token)

    setup_simulation
    run_simulation
  end

  private

  def setup_simulation
    context.api_base = 'http://localhost:3000/api/v1/public'
    context.route_points = [
      { lat: -23.5505, lng: -46.6333, location: "Av. Paulista, 1000" },
      { lat: -23.5510, lng: -46.6340, location: "Av. Paulista, 1200" },
      { lat: -23.5515, lng: -46.6350, location: "Av. Paulista, 1400" },
      { lat: -23.5520, lng: -46.6360, location: "Cruzamento com Rua Augusta" },
      { lat: -23.5525, lng: -46.6370, location: "Rua Augusta, 100" },
      { lat: -23.5530, lng: -46.6380, location: "Rua Augusta, 300" },
      { lat: -23.5535, lng: -46.6390, location: "Rua Augusta, 500 - DESTINO!" }
    ]
  end

  def run_simulation
    puts "🏍️ Iniciando simulação do app do motoboy..."
    puts "📱 Token da entrega: #{context.delivery_token}"

    context.route_points.each_with_index do |point, index|
      puts "\n📍 Passo #{index + 1}/#{context.route_points.length}"
      puts "   Localização: #{point[:location]}"
      puts "   Coordenadas: #{point[:lat]}, #{point[:lng]}"

      response = send_location_update(point[:lat], point[:lng])

      if response[:success]
        puts "   ✅ Localização atualizada com sucesso!"
        puts "   ⏰ ETA atual: #{response[:eta]}"
        puts "   📊 Progresso: #{response[:progress]}%"
      else
        puts "   ❌ Erro ao atualizar localização"
      end

      sleep(10) unless Rails.env.test?
    end

    puts "\n🎉 Simulação concluída! O cliente viu tudo em tempo real no mapa!"
    context.simulation_completed = true
  end

  def send_location_update(latitude, longitude)
    puts "   📡 Enviando: POST #{context.api_base}/track/#{context.delivery_token}/location"

    delivery = Delivery.find_by(public_token: context.delivery_token)
    if delivery
      result = UpdateCourierLocationInteractor.call(
        delivery: delivery,
        latitude: latitude,
        longitude: longitude
      )

      if result.success?
        progress_result = CalculateDeliveryProgressInteractor.call(delivery: delivery)

        {
          success: true,
          eta: extract_eta_from_delivery(delivery),
          progress: progress_result.progress_percentage
        }
      else
        { success: false, error: result.error }
      end
    else
      { success: false, error: 'Entrega não encontrada' }
    end
  end

  def extract_eta_from_delivery(delivery)
    return nil unless delivery.current_estimated_duration

    duration = delivery.current_estimated_duration
    hours = duration / 3600
    minutes = (duration % 3600) / 60

    if hours > 0
      "#{hours}h #{minutes}min"
    else
      "#{minutes}min"
    end
  end
end
