# frozen_string_literal: true

class AddGoogleMapsFieldsToDeliveries < ActiveRecord::Migration[7.1]
  def change
    add_column :deliveries, :estimated_distance, :integer, comment: 'Distance in meters'
    add_column :deliveries, :estimated_duration, :integer, comment: 'Duration in seconds'
    add_column :deliveries, :current_estimated_duration, :integer, comment: 'Current ETA in seconds'
    add_column :deliveries, :route_polyline, :text, comment: 'Encoded polyline for route'
    add_column :deliveries, :route_calculated_at, :datetime
    add_column :deliveries, :eta_calculated_at, :datetime
    add_column :deliveries, :estimated_arrival_at, :datetime
    add_column :deliveries, :route_order, :integer, comment: 'Order in optimized route'

    add_index :deliveries, :estimated_arrival_at
    add_index :deliveries, :route_order
  end
end
