class LocationPing < ApplicationRecord
  include Geospatial

  belongs_to :delivery
  belongs_to :courier

  validates :lat, :lng, presence: true
  validates :lat, inclusion: { in: -90..90 }
  validates :lng, inclusion: { in: -180..180 }
  validates :accuracy, numericality: { greater_than: 0 }, allow_nil: true
  validates :speed, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :recent, -> { where(created_at: 1.hour.ago..Time.current) }
  scope :for_delivery, ->(delivery_id) { where(delivery_id: delivery_id) }

  after_create :broadcast_location_update
  after_create :check_geofence_events
  after_create :cleanup_old_pings

  def coordinates
    [lat, lng]
  end

  def distance_from(other_lat, other_lng)
    Geospatial::DistanceCalculator.call(coordinates, [other_lat, other_lng])
  end

  private

  def broadcast_location_update
    DeliveryChannel.broadcast_to(
      delivery,
      {
        type: 'location_update',
        lat: lat,
        lng: lng,
        speed: speed,
        heading: heading,
        accuracy: accuracy,
        timestamp: created_at.iso8601
      }
    )
  end

  def check_geofence_events
    GeofenceCheckJob.perform_later(delivery.id, id)
  end

  def cleanup_old_pings
    LocationPingCleanupJob.perform_later(delivery.id)
  end
end
