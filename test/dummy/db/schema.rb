# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[6.1].define(version: 2012_06_04_220913) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "default_permission_sets", id: :serial, force: :cascade do |t|
    t.string "joinable_type"
    t.integer "joinable_id"
    t.string "permissions", array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "discussions", id: :serial, force: :cascade do |t|
    t.string "discussable_type"
    t.integer "discussable_id"
  end

  create_table "feeds", id: :serial, force: :cascade do |t|
    t.string "feedable_type"
    t.integer "feedable_id"
  end

  create_table "membership_invitations", id: :serial, force: :cascade do |t|
    t.string "joinable_type"
    t.integer "joinable_id"
    t.integer "user_id"
    t.integer "initiator_id"
    t.string "permissions", array: true
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "membership_requests", id: :serial, force: :cascade do |t|
    t.string "joinable_type"
    t.integer "joinable_id"
    t.integer "user_id"
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "memberships", id: :serial, force: :cascade do |t|
    t.string "joinable_type"
    t.integer "joinable_id"
    t.integer "user_id"
    t.string "permissions", array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permission_links", id: :serial, force: :cascade do |t|
    t.string "joinable_type"
    t.integer "joinable_id"
    t.string "component_type"
    t.integer "component_id"
    t.string "component_view_permission"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.integer "user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
  end

end
