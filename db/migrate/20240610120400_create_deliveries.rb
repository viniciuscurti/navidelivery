class CreateDeliveries < ActiveRecord::Migration[7.0]
  def change
    create_table :deliveries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.references :courier, foreign_key: true
      t.references :user, foreign_key: true
      t.string :status
      t.st_point :pickup_location, geographic: true
      t.st_point :dropoff_location, geographic: true
      t.timestamps
    end
  end
end

