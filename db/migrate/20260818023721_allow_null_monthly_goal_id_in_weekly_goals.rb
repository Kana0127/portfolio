class AllowNullMonthlyGoalIdInWeeklyGoals < ActiveRecord::Migration[8.1]
  def change
    change_column_null :weekly_goals, :monthly_goal_id, true
  end
end
