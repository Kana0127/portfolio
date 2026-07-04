class RoadmapGoal < ApplicationRecord
  # ロードマップゴールは「2〜6か月の中期目標」として扱う
  MIN_DURATION_MONTHS = 2
  MAX_DURATION_MONTHS = 6

  belongs_to :user
  belongs_to :category

  enum :status, {
    active: 0,
    achieved: 1,
    paused: 2,
    canceled: 3
  }

  # status の初期値は active（DB のデフォルトに依存せずモデル側で保証する）
  attribute :status, default: :active

  validates :title, presence: true
  validates :start_month, presence: true
  validates :target_month, presence: true
  validates :status, presence: true

  validate :target_month_after_start_month
  validate :duration_within_range

  private

  def target_month_after_start_month
    return if start_month.blank? || target_month.blank?

    if target_month < start_month
      errors.add(:target_month, "は開始月以降を選択してください")
    end
  end

  # 期間は日数ではなく「年月の差」で判定する（月単位の中期目標のため）
  def duration_within_range
    return if start_month.blank? || target_month.blank?
    return if target_month < start_month

    if month_difference < MIN_DURATION_MONTHS
      errors.add(:target_month, "は開始月から#{MIN_DURATION_MONTHS}か月以上先を選択してください")
    elsif month_difference > MAX_DURATION_MONTHS
      errors.add(:target_month, "は開始月から#{MAX_DURATION_MONTHS}か月以内を選択してください")
    end
  end

  def month_difference
    (target_month.year * 12 + target_month.month) -
      (start_month.year * 12 + start_month.month)
  end
end
