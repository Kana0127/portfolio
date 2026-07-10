class AddRoadmapGoalToMonthlyGoals < ActiveRecord::Migration[8.1]
  def change
    add_reference :monthly_goals, :roadmap_goal, null: true, foreign_key: true
  end
end
