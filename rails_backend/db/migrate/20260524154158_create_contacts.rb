class CreateContacts < ActiveRecord::Migration[7.2]
  def change
    create_table :contacts do |t|
      t.bigint :owner_user_id, null: false
      t.bigint :linked_user_id
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.timestamps
    end

    add_index :contacts, :owner_user_id
    add_index :contacts, :linked_user_id
    add_foreign_key :contacts, :users, column: :owner_user_id
    add_foreign_key :contacts, :users, column: :linked_user_id
  end
end
