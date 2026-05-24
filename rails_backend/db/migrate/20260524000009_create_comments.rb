class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, null: false
      t.references :user,        null: false, foreign_key: true
      t.text       :text,        null: false
      t.timestamps
    end
    add_index :comments, [:commentable_type, :commentable_id]
  end
end
