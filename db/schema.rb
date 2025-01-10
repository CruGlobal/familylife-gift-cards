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

ActiveRecord::Schema[7.2].define(version: 2025_01_07_060614) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "api_keys", force: :cascade do |t|
    t.string "access_token"
    t.string "user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "authentications", force: :cascade do |t|
    t.integer "person_id"
    t.string "provider"
    t.string "uid"
    t.string "token"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "batches", force: :cascade do |t|
    t.string "description"
    t.string "contact"
    t.string "gift_card_type"
    t.decimal "price", precision: 8, scale: 2
    t.integer "registrations_available"
    t.datetime "begin_use_date"
    t.datetime "end_use_date"
    t.datetime "expiration_date"
    t.string "associated_product"
    t.string "isbn"
    t.string "gl_code"
    t.string "dept"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["price"], name: "index_batches_on_price"
    t.index ["registrations_available"], name: "index_batches_on_registrations_available"
  end

  create_table "gift_cards", force: :cascade do |t|
    t.integer "issuance_id"
    t.integer "batch_id"
    t.decimal "price", precision: 8, scale: 2
    t.string "gift_card_type"
    t.string "certificate"
    t.datetime "expiration_date"
    t.integer "registrations_available"
    t.string "associated_product"
    t.decimal "certificate_value"
    t.string "gl_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "isbn"
    t.index ["batch_id"], name: "index_gift_cards_on_batch_id"
    t.index ["issuance_id"], name: "index_gift_cards_on_issuance_id"
    t.index ["price"], name: "index_gift_cards_on_price"
    t.index ["registrations_available"], name: "index_gift_cards_on_registrations_available"
  end

  create_table "issuances", force: :cascade do |t|
    t.string "status"
    t.integer "creator_id"
    t.integer "issuer_id"
    t.integer "batch_id"
    t.integer "quantity"
    t.text "allocated_certificates"
    t.datetime "issued_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_issuances_on_batch_id"
    t.index ["quantity"], name: "index_issuances_on_quantity"
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
