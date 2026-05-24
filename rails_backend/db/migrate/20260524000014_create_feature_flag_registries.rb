class CreateFeatureFlagRegistries < ActiveRecord::Migration[7.2]
  def change
    create_table :feature_flag_registries do |t|
      t.string  :key,            null: false
      t.text    :description
      t.string  :category
      t.boolean :user_toggleable, null: false, default: false
      t.boolean :default_value,   null: false, default: false
      t.timestamps
    end
    add_index :feature_flag_registries, :key, unique: true
  end
end
