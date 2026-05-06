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

ActiveRecord::Schema.define(version: 2026_05_06_100000) do

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.integer "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.text "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "commentable_type", null: false
    t.integer "commentable_id", null: false
    t.text "body", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "gallery_photo_person_tags", force: :cascade do |t|
    t.integer "gallery_photo_id", null: false
    t.integer "person_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["gallery_photo_id", "person_id"], name: "index_gallery_photo_person_tags_unique_pair", unique: true
    t.index ["gallery_photo_id"], name: "index_gallery_photo_person_tags_on_gallery_photo_id"
    t.index ["person_id"], name: "index_gallery_photo_person_tags_on_person_id"
  end

  create_table "gallery_photos", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "caption"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "taken_year"
    t.integer "comments_count", default: 0, null: false
    t.index ["user_id"], name: "index_gallery_photos_on_user_id"
  end

  create_table "ideas", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "comments_count", default: 0, null: false
    t.index ["created_at"], name: "index_ideas_on_created_at"
    t.index ["user_id"], name: "index_ideas_on_user_id"
  end

  create_table "parentships", force: :cascade do |t|
    t.integer "person_id"
    t.integer "father_id"
    t.integer "mother_id"
    t.index ["father_id"], name: "index_parentships_on_father_id"
    t.index ["mother_id"], name: "index_parentships_on_mother_id"
    t.index ["person_id"], name: "index_parentships_on_person_id"
  end

  create_table "partnerships", force: :cascade do |t|
    t.integer "person_id"
    t.integer "partner_id"
    t.date "date_started"
    t.date "date_ended"
    t.string "nature"
    t.index ["partner_id"], name: "index_partnerships_on_partner_id"
    t.index ["person_id"], name: "index_partnerships_on_person_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "gender"
    t.text "bio"
    t.date "date_of_birth"
    t.date "date_of_death"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location_of_birth"
    t.string "location_of_death"
    t.string "chart_id"
    t.string "first_name"
    t.string "last_name"
    t.decimal "birth_latitude", precision: 10, scale: 7
    t.decimal "birth_longitude", precision: 10, scale: 7
    t.decimal "death_latitude", precision: 10, scale: 7
    t.decimal "death_longitude", precision: 10, scale: 7
    t.boolean "birth_date_year_only", default: false, null: false
    t.boolean "death_date_year_only", default: false, null: false
    t.index ["chart_id"], name: "index_people_on_chart_id", unique: true
  end

  create_table "person_facts", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["person_id"], name: "index_person_facts_on_person_id"
    t.index ["user_id"], name: "index_person_facts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "jti", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "person_id"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.string "role", default: "user", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["person_id"], name: "index_users_on_person_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "users"
  add_foreign_key "gallery_photo_person_tags", "gallery_photos"
  add_foreign_key "gallery_photo_person_tags", "people"
  add_foreign_key "gallery_photos", "users"
  add_foreign_key "ideas", "users"
  add_foreign_key "parentships", "people"
  add_foreign_key "parentships", "people", column: "father_id"
  add_foreign_key "parentships", "people", column: "mother_id"
  add_foreign_key "partnerships", "people"
  add_foreign_key "partnerships", "people", column: "partner_id"
  add_foreign_key "person_facts", "people"
  add_foreign_key "person_facts", "users"
  add_foreign_key "users", "people"
end
