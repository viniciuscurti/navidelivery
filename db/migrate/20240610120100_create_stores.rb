class CreateStores < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'postgis' unless extension_enabled?('postgis')
    create_table :stores do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :phone
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :stores, [:latitude, :longitude]
    add_index :stores, :active
  end
end
