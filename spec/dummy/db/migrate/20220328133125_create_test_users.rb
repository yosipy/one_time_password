class CreateTestUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :test_users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
  end
end
