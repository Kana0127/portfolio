class WeeklyGoal < ApplicationRecord
  # 月目標に紐づく週目標は最大5週まで（week_number 1..5）
  MAX_WEEKS = 5

  belongs_to :monthly_goal
  has_many :daily_records, dependent: :destroy
  has_one :weekly_review, dependent: :destroy

  before_validation :assign_week_number

  validates :title, presence: true
  validates :week_number, presence: true, inclusion: { in: 1..MAX_WEEKS }
  validates :start_date, presence: true
  validate :start_date_must_be_valid_candidate

  # 対象月で選択可能な start_date 候補を返す。
  # ルール：
  # - 対象月の1日が日曜の場合：その月のSundayたち（最大MAX_WEEKS個）
  # - 対象月の1日が日曜でない場合：1日 + その月のSundayたち（合計最大MAX_WEEKS個）
  # 例（2026-05 / 5/1=金）→ [5/1, 5/3, 5/10, 5/17, 5/24]
  # 例（2026-06 / 6/1=月）→ [6/1, 6/7, 6/14, 6/21, 6/28]
  def self.start_date_candidates(target_month)
    return [] if target_month.blank?

    first_day = target_month.beginning_of_month
    last_day  = target_month.end_of_month
    sundays   = (first_day..last_day).select(&:sunday?)

    if first_day.sunday?
      sundays.first(MAX_WEEKS)
    else
      ([ first_day ] + sundays).first(MAX_WEEKS)
    end
  end

  # start_date から week_number を自動算出する（候補内位置 + 1）
  # 候補外なら nil
  def self.calc_week_number(start_date, target_month)
    idx = start_date_candidates(target_month).index(start_date)
    idx ? idx + 1 : nil
  end

  # today が対象月の何週目に該当するかを返す。
  # today が target_month の範囲外なら nil。
  # 例：May 2026, today=5/22 → 候補 [5/1, 5/3, 5/10, 5/17, 5/24]
  #     5/22 以下で最大の候補は 5/17 → 第4週
  def self.current_week_number(today, target_month)
    return nil if target_month.blank?
    return nil unless today.between?(target_month.beginning_of_month, target_month.end_of_month)

    idx = start_date_candidates(target_month).rindex { |d| d <= today }
    idx ? idx + 1 : nil
  end

  private

  def assign_week_number
    return unless monthly_goal && start_date
    self.week_number = self.class.calc_week_number(start_date, monthly_goal.target_month)
  end

  def start_date_must_be_valid_candidate
    return if start_date.blank? || monthly_goal.blank?

    candidates = self.class.start_date_candidates(monthly_goal.target_month)
    return if candidates.include?(start_date)

    errors.add(:start_date, "は対象月の1日または対象月内の日曜日（最大5週）から選んでください")
  end
end
