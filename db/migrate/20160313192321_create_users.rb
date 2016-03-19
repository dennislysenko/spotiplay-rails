class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.text :spotify_auth_hash
      t.string :google_email
      t.string :google_password_encrypted

      t.timestamps null: false
    end
  end
end
