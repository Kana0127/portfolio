class WeeklyGoal < ApplicationRecord
  belongs_to :monthly_goal

  validates :title, presence: true
  validates :week_number, presence: true, inclusion: { in: 1..5 }
  validates :start_date, presence: true
end
