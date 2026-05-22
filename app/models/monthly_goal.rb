class MonthlyGoal < ApplicationRecord
  belongs_to :user
  belongs_to :category

  enum :goal_kind, { step: 0, single: 1 }

  validates :title, presence: true
  validates :target_month, presence: true
  validates :goal_kind, presence: true
end
