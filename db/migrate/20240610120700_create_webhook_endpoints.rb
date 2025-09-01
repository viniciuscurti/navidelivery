class CreateWebhookEndpoints < ActiveRecord::Migration[7.0]
  def change
    create_table :webhook_endpoints do |t|
      t.references :account, null: false, foreign_key: true
      t.string :url, null: false
      t.string :event_type
      t.timestamps
    end
  end
end

