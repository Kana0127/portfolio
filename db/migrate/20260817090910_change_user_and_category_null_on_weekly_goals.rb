class ChangeUserAndCategoryNullOnWeeklyGoals < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE weekly_goals
      SET user_id = monthly_goals.user_id
      FROM monthly_goals
      WHERE weekly_goals.monthly_goal_id = monthly_goals.id
        AND weekly_goals.user_id IS NULL;
    SQL

    execute <<~SQL
      UPDATE weekly_goals
      SET category_id = monthly_goals.category_id
      FROM monthly_goals
      WHERE weekly_goals.monthly_goal_id = monthly_goals.id
        AND weekly_goals.category_id IS NULL;
    SQL

    change_column_null :weekly_goals, :user_id, false
    change_column_null :weekly_goals, :category_id, false
  end

  def down
    change_column_null :weekly_goals, :user_id, true
    change_column_null :weekly_goals, :category_id, true
  end
end
