class AddCaseInsensitiveIndexToCategories < ActiveRecord::Migration[7.2]
  def up
    remove_index :categories, [:user_id, :name]
    execute "CREATE UNIQUE INDEX index_categories_on_user_id_and_lower_name ON categories (user_id, lower(name))"
  end

  def down
    execute "DROP INDEX IF EXISTS index_categories_on_user_id_and_lower_name"
    add_index :categories, [:user_id, :name], unique: true
  end
end
