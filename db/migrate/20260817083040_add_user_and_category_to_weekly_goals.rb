class AddUserAndCategoryToWeeklyGoals < ActiveRecord::Migration[8.1]
  def change
    add_reference :weekly_goals, :user, null: true, foreign_key: true
    add_reference :weekly_goals, :category, null: true, foreign_key: true
  end
end
