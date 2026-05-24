class CreateGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :groups do |t|
      t.string     :name,        null: false
      t.text       :description, default: ""
      t.references :created_by,  null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
