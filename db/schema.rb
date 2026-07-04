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

ActiveRecord::Schema[8.1].define(version: 2026_07_01_131303) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "daily_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "memo"
    t.date "record_date", null: false
    t.integer "status", null: false
    t.datetime "updated_at", null: false
    t.bigint "weekly_goal_id", null: false
    t.index ["weekly_goal_id", "record_date"], name: "index_daily_records_on_wg_and_record_date", unique: true
    t.index ["weekly_goal_id"], name: "index_daily_records_on_weekly_goal_id"
  end

  create_table "monthly_goals", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.integer "goal_kind", null: false
    t.date "target_month", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_monthly_goals_on_category_id"
    t.index ["user_id"], name: "index_monthly_goals_on_user_id"
  end

  create_table "monthly_reviews", force: :cascade do |t|
    t.integer "achievement_rate", null: false
    t.datetime "created_at", null: false
    t.text "good_point", null: false
    t.text "improvement_point", null: false
    t.text "memo"
    t.bigint "monthly_goal_id", null: false
    t.datetime "updated_at", null: false
    t.index ["monthly_goal_id"], name: "index_monthly_reviews_on_monthly_goal_id", unique: true
  end

  create_table "roadmap_goals", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "reason"
    t.date "start_month"
    t.integer "status"
    t.date "target_month"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_roadmap_goals_on_category_id"
    t.index ["user_id"], name: "index_roadmap_goals_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "crypted_password"
    t.string "email", null: false
    t.string "name", null: false
    t.string "salt"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "weekly_goals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "monthly_goal_id", null: false
    t.date "start_date", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "week_number", null: false
    t.index ["monthly_goal_id"], name: "index_weekly_goals_on_monthly_goal_id"
  end

  create_table "weekly_reviews", force: :cascade do |t|
    t.integer "achievement_rate", null: false
    t.datetime "created_at", null: false
    t.text "good_point", null: false
    t.text "improvement_point", null: false
    t.text "memo"
    t.datetime "updated_at", null: false
    t.bigint "weekly_goal_id", null: false
    t.index ["weekly_goal_id"], name: "index_weekly_reviews_on_weekly_goal_id", unique: true
  end

  add_foreign_key "daily_records", "weekly_goals"
  add_foreign_key "monthly_goals", "categories"
  add_foreign_key "monthly_goals", "users"
  add_foreign_key "monthly_reviews", "monthly_goals"
  add_foreign_key "roadmap_goals", "categories"
  add_foreign_key "roadmap_goals", "users"
  add_foreign_key "weekly_goals", "monthly_goals"
  add_foreign_key "weekly_reviews", "weekly_goals"
end
