class RoadmapGoal < ApplicationRecord
  belongs_to :user
  belongs_to :category

  enum :status, {
    active: 0,
    achieved: 1,
    paused: 2,
    canceled: 3
  }

  validates :title, presence: true
  validates :start_month, presence: true
  validates :target_month, presence: true
  validates :status, presence: true

  validate :target_month_after_start_month

  private

  def target_month_after_start_month
    return if start_month.blank? || target_month.blank?

    if target_month < start_month
      errors.add(:target_month, "は開始月以降を選択してください")
    end
  end
end