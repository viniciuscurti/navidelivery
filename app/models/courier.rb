class Courier < ApplicationRecord
  belongs_to :account
  has_many :deliveries, dependent: :nullify
  has_many :location_pings, dependent: :destroy
  has_paper_trail

  validates :name, presence: true
  validates :phone, presence: true

  # Callbacks para geocodificação automática
  after_update :geocode_address_if_changed, if: :saved_change_to_address?, unless: :skip_geocoding_callbacks?
  after_create :geocode_address_async, unless: :skip_geocoding_callbacks?

  scope :geocoded, -> { where.not(latitude: nil, longitude: nil) }
  scope :not_geocoded, -> { where(latitude: nil, longitude: nil) }
  scope :with_pending_deliveries, -> { joins(:deliveries).where(deliveries: { status: 'pending' }).distinct }

  def geocoded?
    latitude.present? && longitude.present?
  end

  def full_address
    address
  end

  def coordinates
    return nil unless geocoded?
    [latitude, longitude]
  end

  def location_hash
    return nil unless geocoded?
    { lat: latitude.to_f, lng: longitude.to_f }
  end

  # Pegar última localização conhecida
  def current_location
    last_ping = location_pings.order(pinged_at: :desc).first
    return location_hash if last_ping.nil?

    # Extrair coordenadas do PostGIS point
    if last_ping.location.present?
      { lat: last_ping.location.y, lng: last_ping.location.x }
    else
      location_hash
    end
  end

  private

  def geocode_address_if_changed
    return unless address.present?
    geocode_address_async
  end

  def geocode_address_async
    return unless address.present?
    GoogleMapsProcessingJob.perform_later('geocode_courier', id)
  end

  def skip_geocoding_callbacks?
    Rails.env.test? || defined?(RSpec)
  end
end
