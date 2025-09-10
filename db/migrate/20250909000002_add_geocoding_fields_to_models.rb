# frozen_string_literal: true

class AddGeocodingFieldsToModels < ActiveRecord::Migration[7.1]
  def change
    add_column :couriers, :latitude, :decimal, precision: 10, scale: 6
    add_column :couriers, :longitude, :decimal, precision: 10, scale: 6
    add_column :couriers, :address, :text
    add_column :couriers, :geocoded_at, :datetime

    unless column_exists?(:stores, :latitude)
      add_column :stores, :latitude, :decimal, precision: 10, scale: 6
    end
    unless column_exists?(:stores, :longitude)
      add_column :stores, :longitude, :decimal, precision: 10, scale: 6
    end
    unless column_exists?(:stores, :address)
      add_column :stores, :address, :text
    end
    unless column_exists?(:stores, :geocoded_at)
      add_column :stores, :geocoded_at, :datetime
    end

    unless table_exists?(:customers)
      create_table :customers do |t|
        t.references :account, null: false, foreign_key: true
        t.string :name, null: false
        t.string :email
        t.string :phone
        t.text :address
        t.decimal :latitude, precision: 10, scale: 6
        t.decimal :longitude, precision: 10, scale: 6
        t.datetime :geocoded_at

        t.timestamps
      end

      add_index :customers, [:latitude, :longitude]
    end

    unless column_exists?(:deliveries, :customer_id)
      add_reference :deliveries, :customer, foreign_key: true
    end

    add_index :couriers, [:latitude, :longitude]
    unless index_exists?(:stores, [:latitude, :longitude])
      add_index :stores, [:latitude, :longitude]
    end
  end
end
