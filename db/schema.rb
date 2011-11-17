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

ActiveRecord::Schema.define(:version => 20111117215343) do

  create_table "active_admin_comments", :force => true do |t|
    t.integer  "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "annotation_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "annotations", :force => true do |t|
    t.integer  "part_id"
    t.integer  "start"
    t.integer  "end"
    t.integer  "annotation_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_part_id"
  end

  create_table "automatic_annotations", :force => true do |t|
    t.integer  "part_type_id"
    t.integer  "collection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "annotate_with_part_type_id"
  end

  create_table "characterization_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "characterizations", :force => true do |t|
    t.integer  "replicate_id"
    t.integer  "characterization_type_id"
    t.string   "file_path"
    t.text     "description",              :limit => 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "value"
    t.float    "standard_deviation"
  end

  create_table "characterizations_performances", :id => false, :force => true do |t|
    t.integer "performance_id"
    t.integer "characterization_id"
  end

  create_table "collections", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
  end

  create_table "collections_parts", :id => false, :force => true do |t|
    t.integer "collection_id"
    t.integer "part_id"
  end

  create_table "data_files", :force => true do |t|
    t.string   "content_type"
    t.string   "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "data_file_set_id"
    t.string   "type_name"
  end

  create_table "data_files_plate_wells", :id => false, :force => true do |t|
    t.integer "data_file_id"
    t.integer "plate_well_id"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "eous", :force => true do |t|
    t.integer  "promoter_id"
    t.integer  "five_prime_utr_id"
    t.integer  "cds_id"
    t.integer  "terminator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "comment"
  end

  create_table "measurement_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "measurements", :force => true do |t|
    t.integer  "characterization_id"
    t.integer  "measurement_type_id"
    t.float    "value"
    t.datetime "measured_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organisms", :force => true do |t|
    t.string   "species"
    t.string   "strain"
    t.string   "substrain"
    t.string   "url"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "sequence",   :limit => 255
  end

  create_table "part_types", :force => true do |t|
    t.string   "name"
    t.text     "description", :limit => 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "parts", :force => true do |t|
    t.string   "biofab_id"
    t.text     "sequence",        :limit => 255
    t.text     "description",     :limit => 255
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "plasmid_info_id"
    t.integer  "part_type_id"
    t.integer  "project_id"
    t.text     "duplicates"
  end

  create_table "performance_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "performances", :force => true do |t|
    t.integer  "strain_id"
    t.integer  "performance_type_id"
    t.float    "value"
    t.float    "standard_deviation"
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "performances_reliabilities", :id => false, :force => true do |t|
    t.integer "reliability_id"
    t.integer "performance_id"
  end

  create_table "plasmid_infos", :force => true do |t|
    t.integer  "eou_id"
    t.integer  "integration_index"
    t.text     "before_sequence",    :limit => 255
    t.text     "after_sequence",     :limit => 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "resistance_markers"
    t.string   "ori"
  end

  create_table "plate_layout_wells", :force => true do |t|
    t.integer  "plate_layout_id"
    t.integer  "row"
    t.integer  "column"
    t.integer  "eou_id"
    t.integer  "organism_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "comment"
    t.string   "channel"
    t.boolean  "background"
    t.boolean  "reference"
  end

  create_table "plate_layouts", :force => true do |t|
    t.string   "name"
    t.boolean  "hide_global_wells"
    t.integer  "eou_id"
    t.integer  "organism_id"
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "channel"
  end

  create_table "plate_wells", :force => true do |t|
    t.integer  "plate_id"
    t.integer  "replicate_id"
    t.string   "row"
    t.string   "column"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "plates", :force => true do |t|
    t.string   "name"
    t.text     "description",     :limit => 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "plate_layout_id"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_project_id"
  end

  create_table "projects_users", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "user_id"
  end

  create_table "reliabilities", :force => true do |t|
    t.integer  "type_id"
    t.integer  "part_id"
    t.float    "value"
    t.float    "standard_deviation"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reliability_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "replicates", :force => true do |t|
    t.integer  "strain_id"
    t.integer  "number"
    t.text     "description", :limit => 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  create_table "sequencings", :force => true do |t|
    t.integer  "forward_primer_id"
    t.integer  "reverse_primer_id"
    t.text     "expected_sequence", :limit => 255
    t.string   "abi_file_path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
  end

  create_table "strains", :force => true do |t|
    t.string   "biofab_id"
    t.integer  "organism_id"
    t.integer  "plasmid_id"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location_path"
    t.integer  "project_id"
    t.string   "old_location"
    t.datetime "frozen_date"
    t.string   "frozen_by"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
  end

  add_index "users", ["remember_me_token"], :name => "index_users_on_remember_me_token"

end
