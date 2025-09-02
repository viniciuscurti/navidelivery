class AddDeliveredFieldsToDeliveries < ActiveRecord::Migration[7.1]
  def change
    add_column :deliveries, :delivered_address, :string
    add_column :deliveries, :delivered_at, :datetime
    add_index :deliveries, :delivered_at
  end
end
