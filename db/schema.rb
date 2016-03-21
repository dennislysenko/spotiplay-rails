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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160321180118) do

  create_table "google_playlists", force: :cascade do |t|
    t.string   "google_id"
    t.string   "name"
    t.string   "description"
    t.text     "google_json"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "user_id"
    t.boolean  "should_sync"
    t.integer  "spotify_playlist_id"
  end

  add_index "google_playlists", ["spotify_playlist_id"], name: "index_google_playlists_on_spotify_playlist_id"
  add_index "google_playlists", ["user_id"], name: "index_google_playlists_on_user_id"

  create_table "google_tracks", force: :cascade do |t|
    t.text     "google_json"
    t.string   "google_entry_id"
    t.string   "google_id"
    t.string   "title"
    t.string   "artist"
    t.string   "album"
    t.integer  "google_playlist_id"
    t.integer  "spotify_track_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "duration_ms"
  end

  add_index "google_tracks", ["google_playlist_id"], name: "index_google_tracks_on_google_playlist_id"
  add_index "google_tracks", ["spotify_track_id"], name: "index_google_tracks_on_spotify_track_id"

  create_table "spotify_playlists", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "google_playlist_id"
    t.string   "name"
    t.text     "spotify_json"
    t.string   "spotify_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "spotify_author_id"
  end

  add_index "spotify_playlists", ["google_playlist_id"], name: "index_spotify_playlists_on_google_playlist_id"
  add_index "spotify_playlists", ["user_id"], name: "index_spotify_playlists_on_user_id"

  create_table "spotify_tracks", force: :cascade do |t|
    t.text     "spotify_json"
    t.string   "spotify_id"
    t.string   "title"
    t.string   "artist"
    t.string   "album"
    t.integer  "spotify_playlist_id"
    t.integer  "google_track_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "duration_ms"
  end

  add_index "spotify_tracks", ["google_track_id"], name: "index_spotify_tracks_on_google_track_id"
  add_index "spotify_tracks", ["spotify_playlist_id"], name: "index_spotify_tracks_on_spotify_playlist_id"

  create_table "users", force: :cascade do |t|
    t.string   "google_email"
    t.string   "google_password_encrypted"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "spotify_id"
    t.string   "spotify_access_token"
    t.string   "spotify_refresh_token"
    t.string   "google_password_iv"
  end

end
