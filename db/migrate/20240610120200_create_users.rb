class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.references :account, null: false, foreign_key: true
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :name
      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end

