class AddGooglePasswordIvToUsers < ActiveRecord::Migration
  def change
    add_column :users, :google_password_iv, :string
  end
end
