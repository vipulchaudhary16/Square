class AddColorToCategories < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :color, :string, null: true
  end
end
