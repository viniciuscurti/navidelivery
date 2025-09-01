class CreateCouriers < ActiveRecord::Migration[7.0]
  def change
    create_table :couriers do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone
      t.timestamps
    end
  end
end

