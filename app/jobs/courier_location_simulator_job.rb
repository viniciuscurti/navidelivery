# frozen_string_literal: true

class CourierLocationSimulatorJob < ApplicationJob
  queue_as :default

  def perform(delivery_id, start_lat, start_lng, end_lat, end_lng, duration_minutes = 15)
    delivery = Delivery.find(delivery_id)
    return unless delivery.courier

    steps = duration_minutes * 2 # Atualizar a cada 30 segundos
    lat_step = (end_lat - start_lat) / steps
    lng_step = (end_lng - start_lng) / steps

    puts "🏍️ Simulando entrega #{delivery.external_order_code} - #{steps} passos em #{duration_minutes} min"

    steps.times do |i|
      current_lat = start_lat + (lat_step * i)
      current_lng = start_lng + (lng_step * i)

      # Atualizar localização do motoboy
      delivery.update_courier_location!(current_lat, current_lng)

      puts "📍 Passo #{i+1}/#{steps}: #{current_lat.round(6)}, #{current_lng.round(6)}"

      # Aguardar 30 segundos antes da próxima atualização
      sleep(30) unless Rails.env.test?
    end

    # Finalizar entrega
    delivery.update!(status: 'delivered')
    delivery.broadcast_status_update!

    puts "✅ Entrega #{delivery.external_order_code} concluída!"
  end
end
