# Concern para funcionalidades geoespaciais
module Geospatial
  extend ActiveSupport::Concern

  def coordinates
    [lat, lng] if respond_to?(:lat) && respond_to?(:lng)
  end

  def distance_from(other_lat, other_lng)
    return nil unless coordinates

    # Haversine formula para cálculo de distância
    rad_per_deg = Math::PI / 180
    rkm = 6371
    rm = rkm * 1000

    dlat_rad = (other_lat - lat) * rad_per_deg
    dlng_rad = (other_lng - lng) * rad_per_deg

    lat1_rad = lat * rad_per_deg
    lat2_rad = other_lat * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlng_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    rm * c
  end


  def self.distance_between(coord1, coord2)
    lat1, lng1 = coord1
    lat2, lng2 = coord2
    rad_per_deg = Math::PI / 180
    rkm = 6371
    rm = rkm * 1000
    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlng_rad = (lng2 - lng1) * rad_per_deg
    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg
    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlng_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    rm * c
  end

  module ClassMethods
    def within_radius(lat, lng, radius_meters)
      # Usar PostGIS para queries eficientes
      where(
        "ST_DWithin(ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, location, ?)",
        lng, lat, radius_meters
      )
    end

    # Mantém a API de classe para modelos que incluem este concern
    def distance_between(coord1, coord2)
      Geospatial.distance_between(coord1, coord2)
    end
  end
end
