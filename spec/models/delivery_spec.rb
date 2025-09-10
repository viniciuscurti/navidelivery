require 'rails_helper'

RSpec.describe Delivery, type: :model do
  describe 'associations' do
    it { should belong_to(:store) }
    it { should belong_to(:courier).optional }
    it { should have_many(:location_pings).dependent(:destroy) }
    it { should have_one(:route).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:external_order_code) }
    it { should validate_presence_of(:pickup_address) }
    it { should validate_presence_of(:dropoff_address) }
    it { should validate_presence_of(:pickup_lat) }
    it { should validate_presence_of(:pickup_lng) }
    it { should validate_presence_of(:dropoff_lat) }
    it { should validate_presence_of(:dropoff_lng) }
    it { should validate_presence_of(:public_token) }
    it { should validate_uniqueness_of(:public_token) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(Delivery::STATUSES.index_with(&:to_sym)) }
  end

  describe 'scopes' do
    let!(:delivered_delivery) { create(:delivery, :delivered) }
    let!(:active_delivery) { create(:delivery, :en_route) }
    let!(:today_delivery) { create(:delivery, created_at: Time.current) }
    let!(:yesterday_delivery) { create(:delivery, created_at: 1.day.ago) }

    it 'filters active deliveries' do
      expect(Delivery.active).to include(active_delivery)
      expect(Delivery.active).not_to include(delivered_delivery)
    end

    it 'filters today deliveries' do
      expect(Delivery.today).to include(today_delivery)
      expect(Delivery.today).not_to include(yesterday_delivery)
    end
  end

  describe 'callbacks' do
    let(:delivery) { create(:delivery) }

    it 'generates public token before creation' do
      expect(delivery.public_token).to be_present
      expect(delivery.public_token.length).to be >= 32
    end

    it 'broadcasts status change after update' do
      expect(DeliveryChannel).to receive(:broadcast_to)
      delivery.update(status: 'assigned')
    end
  end

  describe '#public_tracking_url' do
    let(:delivery) { create(:delivery) }

    it 'returns correct tracking URL' do
      expect(delivery.public_tracking_url).to include(delivery.public_token)
    end
  end

  describe '#current_location' do
    let(:delivery) { create(:delivery) }
    let!(:old_ping) { create(:location_ping, delivery: delivery, created_at: 1.hour.ago) }
    let!(:recent_ping) { create(:location_ping, delivery: delivery, created_at: 10.minutes.ago) }

    it 'returns the most recent location ping' do
      expect(delivery.current_location).to eq(recent_ping)
    end
  end
end
