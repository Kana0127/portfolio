class ChangeUserAndCategoryNullOnWeeklyGoals < ActiveRecord::Migration[8.1]
  def change
    change_column_null :weekly_goals, :user_id, false
    change_column_null :weekly_goals, :category_id, false
  end
end
