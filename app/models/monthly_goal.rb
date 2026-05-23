class MonthlyGoal < ApplicationRecord
  belongs_to :user
  belongs_to :category

  has_many :weekly_goals, dependent: :destroy

  enum :goal_kind, { step: 0, single: 1 }

  validates :title, presence: true
  validates :target_month, presence: true
  validates :goal_kind, presence: true
end
