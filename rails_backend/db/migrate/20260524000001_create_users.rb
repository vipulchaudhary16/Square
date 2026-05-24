class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string  :username,          null: false, default: ""
      t.string  :first_name,        null: false, default: ""
      t.string  :last_name,         null: false, default: ""
      t.string  :email,             null: false
      t.string  :password_digest,   null: false
      t.string  :otp
      t.datetime :otp_expiry
      t.string  :reset_token
      t.datetime :reset_token_expiry
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :reset_token
    add_index :users, :username
  end
end
