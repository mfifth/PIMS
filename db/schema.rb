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

ActiveRecord::Schema[8.0].define(version: 2025_03_27_230240) do
  create_table "accounts", force: :cascade do |t|
    t.integer "users_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "orders_id"
    t.integer "suppliers_id"
    t.integer "locations_id"
    t.integer "products_id"
    t.boolean "text_notification", default: false
    t.boolean "email_notification", default: false
    t.index ["locations_id"], name: "index_accounts_on_locations_id"
    t.index ["orders_id"], name: "index_accounts_on_orders_id"
    t.index ["products_id"], name: "index_accounts_on_products_id"
    t.index ["suppliers_id"], name: "index_accounts_on_suppliers_id"
    t.index ["users_id"], name: "index_accounts_on_users_id"
  end

  create_table "batches", force: :cascade do |t|
    t.string "batch_number", null: false
    t.integer "notification_days_before_expiration"
    t.date "manufactured_date"
    t.date "expiration_date"
    t.references "supplier", foreign_key: true, null: false
    t.references "account", foreign_key: true, null: false
    t.timestamps
  end


  create_table "inventory_items", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "quantity", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "daily_usage"
    t.integer "low_threshold"
    t.integer "location_id"
    t.index ["location_id"], name: "index_inventory_items_on_location_id"
    t.index ["product_id"], name: "index_inventory_items_on_product_id"
  end

  create_table "location_product_capacities", force: :cascade do |t|
    t.integer "location_id", null: false
    t.integer "product_id", null: false
    t.integer "capacity", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_location_product_capacities_on_location_id"
    t.index ["product_id"], name: "index_location_product_capacities_on_product_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "address", null: false
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "account_id"
    t.integer "inventory_items_id"
    t.index ["account_id"], name: "index_locations_on_account_id"
    t.index ["inventory_items_id"], name: "index_locations_on_inventory_items_id"
    t.index ["user_id"], name: "index_locations_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "message"
    t.string "notification_type"
    t.boolean "read"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_notifications_on_account_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "location_id", null: false
    t.integer "quantity"
    t.decimal "price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "batch_id"
    t.index ["batch_id"], name: "index_order_items_on_batch_id"
    t.index ["location_id"], name: "index_order_items_on_location_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "supplier_id", null: false
    t.text "order_memo"
    t.string "status", default: "Pending"
    t.decimal "total_amount", precision: 10, scale: 2
    t.boolean "recurring", default: false
    t.date "arrival_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "replenish_on_arrival", default: false
    t.index ["supplier_id"], name: "index_orders_on_supplier_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "sku", null: false
    t.string "category"
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "perishable", default: false
    t.integer "supplier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "account_id"
    t.integer "batch_id"
    t.index ["account_id"], name: "index_products_on_account_id"
    t.index ["batch_id"], name: "index_products_on_batch_id"
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_name"
    t.string "contact_email"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "account_id"
    t.index ["account_id"], name: "index_suppliers_on_account_id"
    t.index ["user_id"], name: "index_suppliers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "account_id"
    t.string "phone"
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "inventory_items", "products"
  add_foreign_key "location_product_capacities", "locations"
  add_foreign_key "location_product_capacities", "products"
  add_foreign_key "order_items", "locations"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "suppliers"
  add_foreign_key "orders", "users"
  add_foreign_key "products", "suppliers"
  add_foreign_key "sessions", "users"
end
