class Api::V1::DeliveriesController < Api::V1::BaseController
  before_action :set_delivery, only: [:show, :update, :assign, :pings, :status]

  def create
    @delivery = current_account.stores.find(params[:store_id]).deliveries.build(delivery_params)

    if @delivery.save
      # Generate route asynchronously
      RouteCalculationJob.perform_later(@delivery.id)
      # Envia link público via WhatsApp (assíncrono)
      SendTrackingLinkJob.perform_later(@delivery.id)

      render json: delivery_response(@delivery), status: :created
    else
      render json: { errors: @delivery.errors }, status: :unprocessable_entity
    end
  end

  def show
    render json: delivery_response(@delivery)
  end

  def assign
    courier = current_account.couriers.find(params[:courier_id])

    if @delivery.update(courier: courier, status: 'assigned')
      render json: delivery_response(@delivery)
    else
      render json: { errors: @delivery.errors }, status: :unprocessable_entity
    end
  end

  def pings
    ping = @delivery.location_pings.build(ping_params.merge(courier: @delivery.courier))

    if ping.save
      head :no_content
    else
      render json: { errors: ping.errors }, status: :unprocessable_entity
    end
  end

  def status
    render json: {
      id: @delivery.id,
      status: @delivery.status,
      current_location: @delivery.current_location&.coordinates,
      estimated_arrival: @delivery.estimated_arrival_time&.iso8601,
      updated_at: @delivery.updated_at.iso8601
    }
  end

  private

  def set_delivery
    @delivery = current_account.deliveries.find(params[:id])
  end

  def delivery_params
    params.require(:delivery).permit(
      :external_order_code, :pickup_address, :dropoff_address,
      :pickup_lat, :pickup_lng, :dropoff_lat, :dropoff_lng,
      :customer_name, :customer_phone, :notes
    )
  end

  def ping_params
    params.require(:ping).permit(:lat, :lng, :speed, :heading, :accuracy, :battery)
  end

  def delivery_response(delivery)
    {
      id: delivery.id,
      external_order_code: delivery.external_order_code,
      status: delivery.status,
      public_tracking_url: delivery.public_tracking_url,
      pickup_address: delivery.pickup_address,
      dropoff_address: delivery.dropoff_address,
      estimated_arrival: delivery.estimated_arrival_time&.iso8601,
      created_at: delivery.created_at.iso8601,
      updated_at: delivery.updated_at.iso8601
    }
  end
end
