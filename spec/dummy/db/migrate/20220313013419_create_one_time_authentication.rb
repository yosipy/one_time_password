class CreateOneTimeAuthentication < ActiveRecord::Migration[7.0]
  def change
    create_table :one_time_authentications do |t|
      t.integer :function_name, null: false
      t.integer :version, null: false
      t.string :user_key, null: false, index: true
      t.string :client_token
      t.integer :password_length, null: false
      t.string :password_digest, null: false
      t.integer :expires_seconds, null: false
      t.integer :count, null: false, default: 0
      t.integer :max_count, null: false, default: 3

      t.timestamps
    end
  end
end
