# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_20_203041) do

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "population"
  end

  create_table "provinces", force: :cascade do |t|
    t.string "name"
    t.integer "country_id", null: false
    t.decimal "latitude", precision: 10, scale: 5
    t.decimal "longitude", precision: 10, scale: 5
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["country_id"], name: "index_provinces_on_country_id"
  end

  create_table "reports", force: :cascade do |t|
    t.datetime "reported_at"
    t.integer "country_id", null: false
    t.integer "cases"
    t.integer "deaths"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "recovered"
    t.integer "province_id"
    t.integer "cum_cases"
    t.integer "cum_deaths"
    t.integer "cum_recovered"
    t.integer "accel_cases"
    t.integer "accel_deaths"
    t.integer "accel_recovered"
    t.index ["country_id"], name: "index_reports_on_country_id"
    t.index ["province_id"], name: "index_reports_on_province_id"
  end

  add_foreign_key "provinces", "countries"
  add_foreign_key "reports", "countries"
  add_foreign_key "reports", "provinces"
end
