class CreateWeeklyGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_goals do |t|
      t.references :monthly_goal, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :week_number, null: false
      t.date :start_date, null: false

      t.timestamps
    end
  end
end
