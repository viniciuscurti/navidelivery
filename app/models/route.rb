class Route < ApplicationRecord
  belongs_to :delivery

  validates :distance_meters, :duration_seconds, presence: true, numericality: { greater_than: 0 }
  validates :polyline, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def distance_km
    distance_meters / 1000.0
  end

  def duration_minutes
    duration_seconds / 60.0
  end

  def estimated_arrival_time(start_time = Time.current)
    start_time + duration_seconds.seconds
  end
end
