class CreateLocationPings < ActiveRecord::Migration[7.0]
  def change
    create_table :location_pings do |t|
      t.references :courier, null: false, foreign_key: true
      t.st_point :location, geographic: true
      t.datetime :pinged_at, null: false
      t.timestamps
    end
  end
end

