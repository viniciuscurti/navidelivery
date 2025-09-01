# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_09_01_130300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "couriers", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_couriers_on_account_id"
  end

  create_table "deliveries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "store_id", null: false
    t.bigint "courier_id"
    t.bigint "user_id"
    t.string "status"
    t.geography "pickup_location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.geography "dropoff_location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "public_token"
    t.index ["account_id"], name: "index_deliveries_on_account_id"
    t.index ["courier_id"], name: "index_deliveries_on_courier_id"
    t.index ["public_token"], name: "index_deliveries_on_public_token", unique: true
    t.index ["store_id"], name: "index_deliveries_on_store_id"
    t.index ["user_id"], name: "index_deliveries_on_user_id"
  end

  create_table "location_pings", force: :cascade do |t|
    t.bigint "courier_id", null: false
    t.geography "location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.datetime "pinged_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "delivery_id"
    t.index ["courier_id"], name: "index_location_pings_on_courier_id"
    t.index ["delivery_id"], name: "index_location_pings_on_delivery_id"
  end

  create_table "stores", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.geography "location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_stores_on_account_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "plan", null: false
    t.datetime "active_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.text "object_changes"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "url", null: false
    t.string "event_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_webhook_endpoints_on_account_id"
  end

  add_foreign_key "couriers", "accounts"
  add_foreign_key "deliveries", "accounts"
  add_foreign_key "deliveries", "couriers"
  add_foreign_key "deliveries", "stores"
  add_foreign_key "deliveries", "users"
  add_foreign_key "location_pings", "couriers"
  add_foreign_key "location_pings", "deliveries"
  add_foreign_key "stores", "accounts"
  add_foreign_key "subscriptions", "accounts"
  add_foreign_key "users", "accounts"
  add_foreign_key "webhook_endpoints", "accounts"
end
