# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120604220913) do

  create_table "default_permission_sets", :force => true do |t|
    t.integer  "joinable_id"
    t.string   "joinable_type"
    t.text     "permissions"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "discussions", :force => true do |t|
    t.integer "discussable_id"
    t.string  "discussable_type"
  end

  create_table "membership_invitations", :force => true do |t|
    t.integer  "joinable_id"
    t.string   "joinable_type"
    t.integer  "user_id"
    t.integer  "initiator_id"
    t.text     "permissions"
    t.text     "message"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "membership_requests", :force => true do |t|
    t.integer  "joinable_id"
    t.string   "joinable_type"
    t.integer  "user_id"
    t.text     "message"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "memberships", :force => true do |t|
    t.integer  "joinable_id"
    t.string   "joinable_type"
    t.integer  "user_id"
    t.text     "permissions"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "permission_links", :force => true do |t|
    t.integer "joinable_id"
    t.string  "joinable_type"
    t.integer "component_id"
    t.string  "component_type"
    t.string  "component_view_permission"
  end

  create_table "projects", :force => true do |t|
  end

  create_table "users", :force => true do |t|
    t.string "name"
  end

end