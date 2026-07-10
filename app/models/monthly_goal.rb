class MonthlyGoal < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :roadmap_goal, optional: true

  has_many :weekly_goals, dependent: :destroy
  has_one :monthly_review, dependent: :destroy

  enum :goal_kind, { step: 0, single: 1 }

  validates :title, presence: true
  validates :target_month, presence: true
  validates :goal_kind, presence: true

  validate :roadmap_goal_must_belong_to_same_user

  private

  def roadmap_goal_must_belong_to_same_user
    return if roadmap_goal.blank?
    return if roadmap_goal.user_id == user_id

    errors.add(
      :roadmap_goal,
      "は自分のロードマップ目標を選択してください"
    )
  end
end
