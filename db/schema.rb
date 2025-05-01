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

ActiveRecord::Schema[8.0].define(version: 2025_05_01_210552) do
  create_table "accounts", force: :cascade do |t|
    t.integer "users_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "suppliers_id"
    t.integer "locations_id"
    t.integer "products_id"
    t.string "stripe_customer_id"
    t.text "square_access_token"
    t.string "square_merchant_id"
    t.string "square_refresh_token"
    t.string "clover_access_token"
    t.string "clover_merchant_id"
    t.index ["locations_id"], name: "index_accounts_on_locations_id"
    t.index ["products_id"], name: "index_accounts_on_products_id"
    t.index ["suppliers_id"], name: "index_accounts_on_suppliers_id"
    t.index ["users_id"], name: "index_accounts_on_users_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "batches", force: :cascade do |t|
    t.string "batch_number", null: false
    t.date "manufactured_date"
    t.date "expiration_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "supplier_id"
    t.integer "account_id"
    t.integer "notification_days_before_expiration", default: 0
    t.index ["account_id"], name: "index_batches_on_account_id"
    t.index ["supplier_id"], name: "index_batches_on_supplier_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.index ["account_id"], name: "index_categories_on_account_id"
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

  create_table "invitations", force: :cascade do |t|
    t.string "email"
    t.string "token"
    t.integer "account_id", null: false
    t.string "role"
    t.boolean "accepted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "confirmed_at"
    t.index ["account_id"], name: "index_invitations_on_account_id"
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
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "account_id"
    t.integer "inventory_items_id"
    t.string "location_uid"
    t.index ["account_id"], name: "index_locations_on_account_id"
    t.index ["inventory_items_id"], name: "index_locations_on_inventory_items_id"
    t.index ["user_id"], name: "index_locations_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "message"
    t.string "notification_type"
    t.boolean "read", default: false
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

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "sku", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "perishable", default: false
    t.integer "supplier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "account_id"
    t.integer "batch_id"
    t.integer "category_id"
    t.string "unit_type", default: "unit"
    t.index ["account_id"], name: "index_products_on_account_id"
    t.index ["batch_id"], name: "index_products_on_batch_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "recipe_items", force: :cascade do |t|
    t.integer "recipe_id", null: false
    t.integer "product_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.string "unit", default: "unit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_recipe_items_on_product_id"
    t.index ["recipe_id", "product_id"], name: "index_recipe_items_on_recipe_id_and_product_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_items_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "uid", null: false
    t.string "name", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_recipes_on_account_id"
    t.index ["uid"], name: "index_recipes_on_uid", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "stripe_subscription_id"
    t.string "plan", default: "free"
    t.string "status"
    t.datetime "started_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
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
    t.boolean "text_notification", default: false
    t.boolean "email_notification", default: false
    t.boolean "admin", default: false
    t.string "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.datetime "confirmation_token_expires_at"
    t.datetime "confirmed_at"
    t.string "locale", default: "en"
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "batches", "suppliers"
  add_foreign_key "inventory_items", "products"
  add_foreign_key "invitations", "accounts"
  add_foreign_key "location_product_capacities", "locations"
  add_foreign_key "location_product_capacities", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "suppliers"
  add_foreign_key "recipe_items", "products"
  add_foreign_key "recipe_items", "recipes"
  add_foreign_key "recipes", "accounts"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscriptions", "accounts"
end
