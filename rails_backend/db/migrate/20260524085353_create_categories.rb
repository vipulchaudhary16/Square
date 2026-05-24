class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string     :name,        null: false
      t.text       :applies_to,  array: true, default: []
      t.boolean    :is_standard, null: false, default: false
      t.timestamps
    end

    add_index :categories, [:user_id, :name], unique: true
  end
end
