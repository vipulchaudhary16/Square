class CreateGroupInvites < ActiveRecord::Migration[7.2]
  def change
    create_table :group_invites do |t|
      t.references :group,      null: false, foreign_key: true
      t.string     :email,      null: false
      t.string     :token,      null: false
      t.string     :status,     null: false, default: "pending"
      t.datetime   :expires_at, null: false
      t.timestamps
    end
    add_index :group_invites, :token, unique: true
  end
end
