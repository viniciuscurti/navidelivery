class CreateLocationPings < ActiveRecord::Migration[7.0]
  def change
    create_table :location_pings do |t|
      t.references :courier, null: false, foreign_key: true
      t.references :delivery, null: false, foreign_key: true
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.float :accuracy
      t.datetime :pinged_at, null: false
      t.timestamps
    end

    add_index :location_pings, [:latitude, :longitude]
    add_index :location_pings, :pinged_at
    add_index :location_pings, [:courier_id, :pinged_at]
  end
end
