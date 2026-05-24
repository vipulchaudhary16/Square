class CreateActivityLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :activity_logs do |t|
      t.references :loggable, polymorphic: true, null: false
      t.references :user,     null: false, foreign_key: true
      t.string     :action,   null: false
      t.text       :details
      t.timestamps
    end
    add_index :activity_logs, [:loggable_type, :loggable_id]
  end
end
