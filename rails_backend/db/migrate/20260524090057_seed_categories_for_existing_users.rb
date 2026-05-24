class SeedCategoriesForExistingUsers < ActiveRecord::Migration[7.2]
  def up
    User.find_each { |user| CategorySeeder.seed(user) }
  end

  def down
    Category.where(is_standard: true).delete_all
  end
end
