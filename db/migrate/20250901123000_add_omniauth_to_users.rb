class AddOmniauthToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :provider, :string unless column_exists?(:users, :provider)
    add_column :users, :uid, :string unless column_exists?(:users, :uid)
    add_column :users, :name, :string unless column_exists?(:users, :name)
    add_index :users, [:provider, :uid], unique: true unless index_exists?(:users, [:provider, :uid])
  end
end
