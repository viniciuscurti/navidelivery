class Delivery < ApplicationRecord
  include Trackable
  include Geospatial

  belongs_to :store
  belongs_to :courier, optional: true
  has_many :location_pings, dependent: :destroy
  has_one :route, dependent: :destroy

  validates :external_order_code, presence: true
  validates :pickup_address, :dropoff_address, presence: true
  validates :pickup_lat, :pickup_lng, :dropoff_lat, :dropoff_lng, presence: true
  validates :public_token, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  STATUSES = %w[
    created assigned en_route arrived_pickup
    left_pickup arrived_dropoff delivered canceled
  ].freeze

  enum status: STATUSES.index_with(&:to_sym)

  scope :active, -> { where.not(status: [:delivered, :canceled]) }
  scope :today, -> { where(created_at: Date.current.all_day) }

  before_create :generate_public_token
  after_update :broadcast_status_change, if: :saved_change_to_status?

  def public_tracking_url
    Rails.application.routes.url_helpers.public_tracking_url(token: public_token)
  end

  def current_location
    location_pings.order(:created_at).last
  end

  def estimated_arrival_time
    return nil unless route&.duration_seconds && status == 'en_route'

    Time.current + route.duration_seconds.seconds
  end

  def distance_to_pickup
    return nil unless courier&.current_location

    Geospatial::DistanceCalculator.call(
      courier.current_location.coordinates,
      [pickup_lat, pickup_lng]
    )
  end

  def distance_to_dropoff
    return nil unless courier&.current_location

    Geospatial::DistanceCalculator.call(
      courier.current_location.coordinates,
      [dropoff_lat, dropoff_lng]
    )
  end

  private

  def generate_public_token
    self.public_token = SecureRandom.urlsafe_base64(32)
  end

  def broadcast_status_change
    DeliveryChannel.broadcast_to(
      self,
      {
        type: 'status_change',
        status: status,
        updated_at: updated_at.iso8601
      }
    )
  end
end
