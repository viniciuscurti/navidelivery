# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MapsController, type: :controller do
  let(:user) { create(:user) }
  let(:account) { user.account }
  let(:delivery) { create(:delivery, account: account) }
  let(:courier) { create(:courier, account: account) }

  before do
    sign_in user
    allow(ENV).to receive(:[]).with('GOOGLE_MAPS_API_KEY').and_return('test_api_key')
  end

  describe 'POST #geocode' do
    let(:valid_params) { { address: 'Rua das Flores, 123, São Paulo, SP' } }
    let(:maps_service) { instance_double(GoogleMapsService) }

    before do
      allow(GoogleMapsService).to receive(:new).and_return(maps_service)
    end

    context 'with valid address' do
      let(:geocode_response) do
        {
          success: true,
          data: {
            'results' => [
              {
                'formatted_address' => 'Rua das Flores, 123 - Jardins, São Paulo - SP, Brazil',
                'geometry' => {
                  'location' => { 'lat' => -23.5505, 'lng' => -46.6333 }
                },
                'place_id' => 'ChIJAVkDPzdZzpQRMuFuSOAP0kAiU'
              }
            ]
          }
        }
      end

      before do
        allow(maps_service).to receive(:geocode).and_return(geocode_response)
      end

      it 'returns geocoded address data' do
        post :geocode, params: valid_params

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['latitude']).to eq(-23.5505)
        expect(json_response['data']['longitude']).to eq(-46.6333)
      end
    end

    context 'with invalid address' do
      before do
        allow(maps_service).to receive(:geocode).and_return(
          { success: false, error: 'ZERO_RESULTS', message: 'No results found' }
        )
      end

      it 'returns error response' do
        post :geocode, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('ZERO_RESULTS')
      end
    end

    context 'without address parameter' do
      it 'returns bad request' do
        post :geocode, params: {}

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Address parameter is required')
      end
    end
  end

  describe 'POST #validate_address' do
    let(:route_service) { instance_double(DeliveryRouteService) }

    before do
      allow(DeliveryRouteService).to receive(:new).and_return(route_service)
    end

    context 'with valid address' do
      before do
        allow(route_service).to receive(:validate_customer_address).and_return(true)
      end

      it 'returns validation result' do
        post :validate_address, params: { address: 'Valid Address' }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['valid']).to be true
      end
    end

    context 'without address parameter' do
      it 'returns bad request' do
        post :validate_address, params: {}

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'POST #calculate_route' do
    before do
      allow(GoogleMapsProcessingJob).to receive(:perform_later)
    end

    it 'starts route calculation job' do
      post :calculate_route, params: { delivery_id: delivery.id }

      expect(response).to have_http_status(:accepted)
      expect(GoogleMapsProcessingJob).to have_received(:perform_later)
        .with('calculate_route', delivery.id)
    end

    context 'with non-existent delivery' do
      it 'returns not found' do
        post :calculate_route, params: { delivery_id: 999999 }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #update_eta' do
    let(:current_location) { { lat: -23.5505, lng: -46.6333 } }

    before do
      allow(GoogleMapsProcessingJob).to receive(:perform_later)
    end

    it 'starts ETA update job' do
      post :update_eta, params: { delivery_id: delivery.id, current_location: current_location }

      expect(response).to have_http_status(:accepted)
      expect(GoogleMapsProcessingJob).to have_received(:perform_later)
        .with('update_eta', delivery.id, current_location)
    end
  end

  describe 'POST #optimize_route' do
    before do
      allow(GoogleMapsProcessingJob).to receive(:perform_later)
    end

    it 'starts route optimization job' do
      post :optimize_route, params: { courier_id: courier.id }

      expect(response).to have_http_status(:accepted)
      expect(GoogleMapsProcessingJob).to have_received(:perform_later)
        .with('optimize_courier_route', courier.id)
    end
  end

  describe 'GET #calculate_distance' do
    let(:route_service) { instance_double(DeliveryRouteService) }
    let(:distance_data) do
      {
        distance_text: '5.2 km',
        distance_value: 5200,
        duration_text: '12 mins',
        duration_value: 720
      }
    end

    before do
      allow(DeliveryRouteService).to receive(:new).and_return(route_service)
      allow(route_service).to receive(:calculate_distance).and_return(distance_data)
    end

    it 'calculates distance between two points' do
      get :calculate_distance, params: {
        origin: 'São Paulo, SP',
        destination: 'Santos, SP'
      }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']).to eq(distance_data.stringify_keys)
    end

    context 'without required parameters' do
      it 'returns bad request when origin is missing' do
        get :calculate_distance, params: { destination: 'Santos, SP' }

        expect(response).to have_http_status(:bad_request)
      end

      it 'returns bad request when destination is missing' do
        get :calculate_distance, params: { origin: 'São Paulo, SP' }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
