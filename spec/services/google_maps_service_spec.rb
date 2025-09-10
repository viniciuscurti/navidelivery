# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoogleMapsService, type: :service do
  let(:service) { described_class.new }
  let(:api_key) { 'test_api_key' }

  before do
    allow(ENV).to receive(:[]).with('GOOGLE_MAPS_API_KEY').and_return(api_key)
  end

  describe '#initialize' do
    context 'when API key is present' do
      it 'initializes successfully' do
        expect(service.instance_variable_get(:@api_key)).to eq(api_key)
      end
    end

    context 'when API key is missing' do
      before do
        allow(ENV).to receive(:[]).with('GOOGLE_MAPS_API_KEY').and_return(nil)
      end

      it 'raises an ArgumentError' do
        expect { described_class.new }.to raise_error(ArgumentError, 'Google Maps API key not configured')
      end
    end
  end

  describe '#geocode' do
    let(:address) { 'Rua das Flores, 123, São Paulo, SP' }
    let(:successful_response) do
      {
        'status' => 'OK',
        'results' => [
          {
            'formatted_address' => 'Rua das Flores, 123 - Jardins, São Paulo - SP, Brazil',
            'geometry' => {
              'location' => { 'lat' => -23.5505, 'lng' => -46.6333 },
              'location_type' => 'ROOFTOP'
            },
            'place_id' => 'ChIJAVkDPzdZzpQRMuFuSOAP0kAiU'
          }
        ]
      }
    end

    before do
      stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/geocode/json})
        .to_return(
          status: 200,
          body: successful_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'geocodes an address successfully' do
      result = service.geocode(address)

      expect(result[:success]).to be true
      expect(result[:data]['status']).to eq('OK')
      expect(result[:data]['results']).to be_present
    end

    it 'makes the correct API call' do
      service.geocode(address)

      expect(WebMock).to have_requested(:get, 'https://maps.googleapis.com/maps/api/geocode/json')
        .with(query: hash_including('address' => address, 'key' => api_key))
    end
  end

  describe '#reverse_geocode' do
    let(:lat) { -23.5505 }
    let(:lng) { -46.6333 }

    before do
      stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/geocode/json})
        .to_return(
          status: 200,
          body: { 'status' => 'OK', 'results' => [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'reverse geocodes coordinates successfully' do
      result = service.reverse_geocode(lat, lng)

      expect(result[:success]).to be true
      expect(WebMock).to have_requested(:get, 'https://maps.googleapis.com/maps/api/geocode/json')
        .with(query: hash_including('latlng' => "#{lat},#{lng}", 'key' => api_key))
    end
  end

  describe '#distance_matrix' do
    let(:origins) { ['São Paulo, SP'] }
    let(:destinations) { ['Rio de Janeiro, RJ'] }
    let(:successful_response) do
      {
        'status' => 'OK',
        'rows' => [
          {
            'elements' => [
              {
                'status' => 'OK',
                'distance' => { 'text' => '429 km', 'value' => 429000 },
                'duration' => { 'text' => '5 hours 30 mins', 'value' => 19800 },
                'duration_in_traffic' => { 'text' => '6 hours 15 mins', 'value' => 22500 }
              }
            ]
          }
        ]
      }
    end

    before do
      stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/distancematrix/json})
        .to_return(
          status: 200,
          body: successful_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'calculates distance matrix successfully' do
      result = service.distance_matrix(origins, destinations)

      expect(result[:success]).to be true
      expect(result[:data]['status']).to eq('OK')
      expect(result[:data]['rows']).to be_present
    end

    it 'uses default parameters when none provided' do
      service.distance_matrix(origins, destinations)

      expect(WebMock).to have_requested(:get, 'https://maps.googleapis.com/maps/api/distancematrix/json')
        .with(query: hash_including(
          'units' => 'metric',
          'mode' => 'driving',
          'traffic_model' => 'best_guess',
          'departure_time' => 'now'
        ))
    end
  end

  describe '#validate_address' do
    context 'with a valid address' do
      let(:address) { 'Rua das Flores, 123, São Paulo, SP' }

      before do
        stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/geocode/json})
          .to_return(
            status: 200,
            body: {
              'status' => 'OK',
              'results' => [
                {
                  'geometry' => { 'location_type' => 'ROOFTOP' }
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns true for valid address' do
        expect(service.validate_address(address)).to be true
      end
    end

    context 'with an invalid address' do
      let(:address) { 'endereço inválido xyz' }

      before do
        stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/geocode/json})
          .to_return(
            status: 200,
            body: { 'status' => 'ZERO_RESULTS', 'results' => [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns false for invalid address' do
        expect(service.validate_address(address)).to be false
      end
    end
  end

  describe '#calculate_eta' do
    let(:origin) { 'São Paulo, SP' }
    let(:destination) { 'Santos, SP' }

    before do
      stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/distancematrix/json})
        .to_return(
          status: 200,
          body: {
            'status' => 'OK',
            'rows' => [
              {
                'elements' => [
                  {
                    'status' => 'OK',
                    'distance' => { 'text' => '72 km', 'value' => 72000 },
                    'duration' => { 'text' => '1 hour 15 mins', 'value' => 4500 },
                    'duration_in_traffic' => { 'text' => '1 hour 30 mins', 'value' => 5400 }
                  }
                ]
              }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'calculates ETA successfully' do
      result = service.calculate_eta(origin, destination)

      expect(result).to include(
        distance: { 'text' => '72 km', 'value' => 72000 },
        duration: { 'text' => '1 hour 15 mins', 'value' => 4500 },
        duration_in_traffic: { 'text' => '1 hour 30 mins', 'value' => 5400 }
      )
    end
  end

  describe 'error handling' do
    context 'when API returns an error' do
      before do
        stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/geocode/json})
          .to_return(
            status: 200,
            body: { 'status' => 'REQUEST_DENIED', 'error_message' => 'API key invalid' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'handles API errors gracefully' do
        result = service.geocode('test address')

        expect(result[:success]).to be false
        expect(result[:error]).to eq('REQUEST_DENIED')
        expect(result[:message]).to eq('API key invalid')
      end
    end

    context 'when HTTP request fails' do
      before do
        stub_request(:get, %r{https://maps\.googleapis\.com/maps/api/geocode/json})
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'handles HTTP errors gracefully' do
        result = service.geocode('test address')

        expect(result[:success]).to be false
        expect(result[:error]).to eq('HTTP_ERROR')
      end
    end
  end
end
