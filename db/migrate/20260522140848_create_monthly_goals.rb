class CreateMonthlyGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :title, null: false
      t.date :target_month, null: false
      t.integer :goal_kind, null: false

      t.timestamps
    end
  end
end
