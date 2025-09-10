# frozen_string_literal: true

class FixCustomersTable < ActiveRecord::Migration[7.1]
  def up
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
    else
      unless column_exists?(:customers, :latitude)
        add_column :customers, :latitude, :decimal, precision: 10, scale: 6
      end

      unless column_exists?(:customers, :longitude)
        add_column :customers, :longitude, :decimal, precision: 10, scale: 6
      end

      unless column_exists?(:customers, :geocoded_at)
        add_column :customers, :geocoded_at, :datetime
      end

      unless index_exists?(:customers, [:latitude, :longitude])
        add_index :customers, [:latitude, :longitude]
      end
    end
  end

  def down
    drop_table :customers if table_exists?(:customers)
  end
end
