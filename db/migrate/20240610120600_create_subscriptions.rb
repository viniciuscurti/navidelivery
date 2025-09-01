class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :plan, null: false
      t.datetime :active_until
      t.timestamps
    end
  end
end

