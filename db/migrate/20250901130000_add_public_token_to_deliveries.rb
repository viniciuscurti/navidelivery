class AddPublicTokenToDeliveries < ActiveRecord::Migration[7.1]
  def change
    add_column :deliveries, :public_token, :string unless column_exists?(:deliveries, :public_token)
    add_index :deliveries, :public_token, unique: true unless index_exists?(:deliveries, :public_token)
  end
end

