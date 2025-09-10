# frozen_string_literal: true

class Customer < ApplicationRecord
  belongs_to :account
  has_many :deliveries, dependent: :destroy

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, presence: true

  after_update :geocode_address_if_changed, if: :saved_change_to_address?, unless: :skip_geocoding_callbacks?
  after_create :geocode_address_async, unless: :skip_geocoding_callbacks?
  after_create :geocode_address_async

  scope :geocoded, -> { where.not(latitude: nil, longitude: nil) }
  scope :not_geocoded, -> { where(latitude: nil, longitude: nil) }

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

  private

  def geocode_address_if_changed
    return unless address.present?
    geocode_address_async
  end

  def geocode_address_async
    return unless address.present?
    GoogleMapsProcessingJob.perform_later('geocode_customer', id)

  def skip_geocoding_callbacks?
    Rails.env.test? || defined?(RSpec)
  end
  end
end
