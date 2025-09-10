class CreateDeliveries < ActiveRecord::Migration[7.0]
  def change
    create_table :deliveries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.references :courier, foreign_key: true
      t.references :user, foreign_key: true
      t.string :external_order_code, null: false
      t.string :status, default: 'created'

      # Pickup location
      t.string :pickup_address
      t.decimal :pickup_lat, precision: 10, scale: 6
      t.decimal :pickup_lng, precision: 10, scale: 6

      # Dropoff location
      t.string :dropoff_address
      t.decimal :dropoff_lat, precision: 10, scale: 6
      t.decimal :dropoff_lng, precision: 10, scale: 6

      # Customer info
      t.string :customer_name
      t.string :customer_phone

      # Tracking
      t.string :public_token, null: false
      t.datetime :estimated_arrival_time
      t.datetime :delivered_at

      t.timestamps
    end

    add_index :deliveries, :public_token, unique: true
    add_index :deliveries, :status
    add_index :deliveries, [:pickup_lat, :pickup_lng]
    add_index :deliveries, [:dropoff_lat, :dropoff_lng]
    add_index :deliveries, :external_order_code
  end
end
