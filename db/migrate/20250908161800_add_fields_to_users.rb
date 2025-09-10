class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :first_name, :string, null: false
    add_column :users, :last_name, :string, null: false
    add_column :users, :phone, :string
    add_column :users, :role, :integer, default: 0, null: false
    add_column :users, :status, :integer, default: 0, null: false
    add_column :users, :api_token, :string, null: false

    add_index :users, :role
    add_index :users, :status
    add_index :users, :phone
    add_index :users, :api_token, unique: true
  end
end
