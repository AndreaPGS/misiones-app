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

ActiveRecord::Schema[8.1].define(version: 2026_09_10_030000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "guests", force: :cascade do |t|
    t.integer "attempts", default: 1, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "phone"
    t.string "picture"
    t.integer "points", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "guests_missions", id: false, force: :cascade do |t|
    t.bigint "guest_id", null: false
    t.bigint "mission_id", null: false
    t.index ["guest_id", "mission_id"], name: "index_guests_missions_on_guest_id_and_mission_id", unique: true
    t.index ["guest_id"], name: "index_guests_missions_on_guest_id"
    t.index ["mission_id"], name: "index_guests_missions_on_mission_id"
  end

  create_table "mission_assignments", force: :cascade do |t|
    t.datetime "assigned_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "guest_id", null: false
    t.bigint "mission_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["guest_id", "status"], name: "index_mission_assignments_on_guest_id_assigned_unique", unique: true, where: "(status = 0)"
    t.index ["guest_id"], name: "index_mission_assignments_on_guest_id"
    t.index ["mission_id"], name: "index_mission_assignments_on_mission_id"
    t.index ["mission_id"], name: "index_mission_assignments_on_mission_id_unique", unique: true
  end

  create_table "missions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "score", null: false
    t.bigint "target_id", null: false
    t.datetime "updated_at", null: false
    t.index ["target_id"], name: "index_missions_on_target_id"
  end

  create_table "missions_target_guests", id: false, force: :cascade do |t|
    t.bigint "guest_id", null: false
    t.bigint "mission_id", null: false
    t.index ["guest_id"], name: "index_missions_target_guests_on_guest_id"
    t.index ["mission_id", "guest_id"], name: "index_missions_target_guests_on_mission_id_and_guest_id", unique: true
    t.index ["mission_id"], name: "index_missions_target_guests_on_mission_id"
  end

  add_foreign_key "guests_missions", "guests"
  add_foreign_key "guests_missions", "missions"
  add_foreign_key "mission_assignments", "guests"
  add_foreign_key "mission_assignments", "missions"
  add_foreign_key "missions", "guests", column: "target_id"
  add_foreign_key "missions_target_guests", "guests"
  add_foreign_key "missions_target_guests", "missions"
end
