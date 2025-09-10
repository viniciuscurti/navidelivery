# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::DeliveriesController, type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:store) { create(:store, account: account) }
  let(:delivery) { create(:delivery, store: store) }

  describe 'POST /api/v1/deliveries' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          store_id: store.id,
          delivery: {
            external_order_code: 'ORDER123',
            pickup_address: '123 Main St',
            dropoff_address: '456 Oak Ave',
            pickup_lat: -23.5505,
            pickup_lng: -46.6333,
            dropoff_lat: -23.5489,
            dropoff_lng: -46.6388,
            customer_name: 'John Doe',
            customer_phone: '+5511999999999'
          }
        }
      end

      it 'creates a new delivery' do
        expect {
          post '/api/v1/deliveries', params: valid_params, headers: auth_headers(user)
        }.to change(Delivery, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['data']['attributes']['external_order_code']).to eq('ORDER123')
      end

      it 'enqueues background jobs' do
        expect(RouteCalculationJob).to receive(:perform_later)
        expect(SendTrackingLinkJob).to receive(:perform_later)

        post '/api/v1/deliveries', params: valid_params, headers: auth_headers(user)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          store_id: store.id,
          delivery: {
            external_order_code: ''
          }
        }
      end

      it 'returns validation errors' do
        post '/api/v1/deliveries', params: invalid_params, headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        post '/api/v1/deliveries', params: {}

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/deliveries/:id' do
    it 'returns delivery details' do
      get "/api/v1/deliveries/#{delivery.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['id']).to eq(delivery.id.to_s)
    end
  end

  describe 'POST /api/v1/deliveries/:id/assign' do
    let(:courier) { create(:courier, account: account) }

    it 'assigns courier to delivery' do
      post "/api/v1/deliveries/#{delivery.id}/assign",
           params: { courier_id: courier.id },
           headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(delivery.reload.courier).to eq(courier)
      expect(delivery.status).to eq('assigned')
    end
  end
end
