class MonthlyReview < ApplicationRecord
  # 達成率として許可する値（WeeklyReview と同じ4等分の選択肢）
  ACHIEVEMENT_RATES = [ 0, 25, 50, 75, 100 ].freeze

  belongs_to :monthly_goal

  validates :monthly_goal_id, uniqueness: true
  validates :achievement_rate, presence: true, inclusion: { in: ACHIEVEMENT_RATES }
  validates :good_point, presence: true
  validates :improvement_point, presence: true
  # memo は任意入力（presence 不要）
end
