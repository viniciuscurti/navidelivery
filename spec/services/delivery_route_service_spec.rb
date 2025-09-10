# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeliveryRouteService, type: :service do
  let(:service) { described_class.new }
  let(:maps_service) { instance_double(GoogleMapsService) }

  before do
    allow(GoogleMapsService).to receive(:new).and_return(maps_service)
  end

  describe '#calculate_delivery_route' do
    let(:store) { create(:store, :with_coordinates) }
    let(:customer) { create(:customer, :with_coordinates) }
    let(:delivery) { create(:delivery, store: store, customer: customer) }

    let(:google_response) do
      {
        success: true,
        data: {
          'routes' => [
            {
              'legs' => [
                {
                  'distance' => { 'text' => '2.5 km', 'value' => 2500 },
                  'duration' => { 'text' => '8 mins', 'value' => 480 },
                  'start_address' => 'Rua A, 123',
                  'end_address' => 'Rua B, 456',
                  'steps' => []
                }
              ],
              'overview_polyline' => { 'points' => 'encoded_polyline_string' }
            }
          ]
        }
      }
    end

    before do
      allow(maps_service).to receive(:directions).and_return(google_response)
    end

    it 'calculates route for delivery successfully' do
      result = service.calculate_delivery_route(delivery)

      expect(result).to include(
        distance: { 'text' => '2.5 km', 'value' => 2500 },
        duration: { 'text' => '8 mins', 'value' => 480 }
      )
    end

    it 'updates delivery with route information' do
      service.calculate_delivery_route(delivery)
      delivery.reload

      expect(delivery.estimated_distance).to eq(2500)
      expect(delivery.estimated_duration).to eq(480)
      expect(delivery.route_polyline).to eq('encoded_polyline_string')
      expect(delivery.route_calculated_at).to be_present
    end

    context 'when Google Maps API fails' do
      before do
        allow(maps_service).to receive(:directions).and_return(
          { success: false, error: 'API_ERROR' }
        )
      end

      it 'returns nil and logs error' do
        expect(Rails.logger).to receive(:error).with(/Failed to calculate route/)
        result = service.calculate_delivery_route(delivery)
        expect(result).to be_nil
      end
    end
  end

  describe '#calculate_delivery_eta' do
    let(:courier) { create(:courier, :with_coordinates) }
    let(:customer) { create(:customer, :with_coordinates) }
    let(:delivery) { create(:delivery, courier: courier, customer: customer) }

    let(:eta_response) do
      {
        distance: { 'text' => '1.2 km', 'value' => 1200 },
        duration: { 'text' => '4 mins', 'value' => 240 }
      }
    end

    before do
      allow(maps_service).to receive(:calculate_eta).and_return(eta_response)
    end

    it 'calculates ETA successfully' do
      result = service.calculate_delivery_eta(delivery)

      expect(result).to eq(eta_response)
    end

    it 'updates delivery with ETA information' do
      Timecop.freeze do
        service.calculate_delivery_eta(delivery)
        delivery.reload

        expected_arrival = Time.current + 240.seconds
        expect(delivery.estimated_arrival_at).to be_within(1.second).of(expected_arrival)
        expect(delivery.current_estimated_duration).to eq(240)
        expect(delivery.eta_calculated_at).to be_present
      end
    end

    context 'with custom current location' do
      let(:current_location) { { lat: -23.5500, lng: -46.6300 } }

      it 'uses provided current location' do
        service.calculate_delivery_eta(delivery, current_location)

        expect(maps_service).to have_received(:calculate_eta)
          .with(current_location, anything, anything)
      end
    end
  end

  describe '#optimize_multiple_deliveries' do
    let(:courier) { create(:courier, :with_coordinates) }
    let(:customer1) { create(:customer, :with_coordinates, latitude: -23.5489, longitude: -46.6388) }
    let(:customer2) { create(:customer, :with_coordinates, latitude: -23.5510, longitude: -46.6350) }
    let(:deliveries) { [create(:delivery, customer: customer1), create(:delivery, customer: customer2)] }

    let(:optimization_response) do
      {
        success: true,
        data: {
          'routes' => [
            {
              'waypoint_order' => [1, 0] # Optimized order
            }
          ]
        }
      }
    end

    before do
      allow(maps_service).to receive(:optimize_route).and_return(optimization_response)
    end

    it 'optimizes route for multiple deliveries' do
      result = service.optimize_multiple_deliveries(courier, deliveries)

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'updates delivery route order' do
      service.optimize_multiple_deliveries(courier, deliveries)

      deliveries.each(&:reload)
      expect(deliveries.map(&:route_order)).to contain_exactly(1, 2)
    end

    context 'when no deliveries provided' do
      it 'returns empty array' do
        result = service.optimize_multiple_deliveries(courier, [])
        expect(result).to eq([])
      end
    end
  end

  describe '#validate_customer_address' do
    let(:address) { 'Rua das Flores, 123, São Paulo, SP' }

    context 'when address is valid' do
      before do
        allow(maps_service).to receive(:validate_address).and_return(true)
      end

      it 'returns true' do
        expect(service.validate_customer_address(address)).to be true
      end
    end

    context 'when address is invalid' do
      before do
        allow(maps_service).to receive(:validate_address).and_return(false)
      end

      it 'returns false' do
        expect(service.validate_customer_address(address)).to be false
      end
    end
  end

  describe '#geocode_and_save' do
    let(:customer) { create(:customer, address: 'Rua das Flores, 123', latitude: nil, longitude: nil) }
    let(:geocode_response) do
      {
        success: true,
        data: {
          'results' => [
            {
              'geometry' => {
                'location' => { 'lat' => -23.5505, 'lng' => -46.6333 }
              }
            }
          ]
        }
      }
    end

    before do
      allow(maps_service).to receive(:geocode).and_return(geocode_response)
    end

    it 'geocodes and saves coordinates' do
      result = service.geocode_and_save(customer)

      expect(result).to be true
      customer.reload
      expect(customer.latitude).to eq(-23.5505)
      expect(customer.longitude).to eq(-46.6333)
      expect(customer.geocoded_at).to be_present
    end

    context 'when geocoding fails' do
      before do
        allow(maps_service).to receive(:geocode).and_return(
          { success: false, error: 'INVALID_REQUEST' }
        )
      end

      it 'returns false and logs error' do
        expect(Rails.logger).to receive(:error).with(/Failed to geocode address/)
        result = service.geocode_and_save(customer)
        expect(result).to be false
      end
    end

    context 'when address is blank' do
      before do
        customer.update!(address: nil)
      end

      it 'returns false without making API call' do
        result = service.geocode_and_save(customer)
        expect(result).to be false
        expect(maps_service).not_to have_received(:geocode)
      end
    end
  end

  describe '#calculate_distance' do
    let(:point_a) { 'São Paulo, SP' }
    let(:point_b) { 'Santos, SP' }
    let(:distance_response) do
      {
        success: true,
        data: {
          'rows' => [
            {
              'elements' => [
                {
                  'status' => 'OK',
                  'distance' => { 'text' => '72 km', 'value' => 72000 },
                  'duration' => { 'text' => '1 hour 15 mins', 'value' => 4500 }
                }
              ]
            }
          ]
        }
      }
    end

    before do
      allow(maps_service).to receive(:distance_matrix).and_return(distance_response)
    end

    it 'calculates distance between two points' do
      result = service.calculate_distance(point_a, point_b)

      expect(result).to include(
        distance_text: '72 km',
        distance_value: 72000,
        duration_text: '1 hour 15 mins',
        duration_value: 4500
      )
    end

    context 'when distance calculation fails' do
      before do
        allow(maps_service).to receive(:distance_matrix).and_return(
          { success: false }
        )
      end

      it 'returns nil' do
        result = service.calculate_distance(point_a, point_b)
        expect(result).to be_nil
      end
    end
  end

  describe '#courier_near_destination?' do
    let(:courier_location) { { lat: -23.5505, lng: -46.6333 } }
    let(:destination) { { lat: -23.5506, lng: -46.6334 } }

    context 'when courier is within threshold' do
      before do
        allow(service).to receive(:calculate_distance).and_return(
          { distance_value: 50 } # 50 meters
        )
      end

      it 'returns true' do
        result = service.courier_near_destination?(courier_location, destination, 100)
        expect(result).to be true
      end
    end

    context 'when courier is outside threshold' do
      before do
        allow(service).to receive(:calculate_distance).and_return(
          { distance_value: 150 } # 150 meters
        )
      end

      it 'returns false' do
        result = service.courier_near_destination?(courier_location, destination, 100)
        expect(result).to be false
      end
    end

    context 'when distance calculation fails' do
      before do
        allow(service).to receive(:calculate_distance).and_return(nil)
      end

      it 'returns false' do
        result = service.courier_near_destination?(courier_location, destination)
        expect(result).to be false
      end
    end
  end
end
