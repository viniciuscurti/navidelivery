class CreateStores < ActiveRecord::Migration[7.0]
  def change
    create_table :stores do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.st_point :location, geographic: true
      t.timestamps
    end
  end
end

