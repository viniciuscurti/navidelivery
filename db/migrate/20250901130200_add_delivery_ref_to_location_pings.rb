class AddDeliveryRefToLocationPings < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:location_pings, :delivery_id)
      add_reference :location_pings, :delivery, foreign_key: true, null: true
    end
  end
end

