class AddStatusToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :status, :integer, default: 0, null: false
    add_index :accounts, :status
  end
end

