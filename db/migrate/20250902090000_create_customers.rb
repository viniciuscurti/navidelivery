class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :address, null: false
      t.string :zip_code, null: false
      t.string :phone, null: false

      t.timestamps
    end

    add_index :customers, [:account_id, :phone]
    add_index :customers, [:account_id, :name]
  end
end
