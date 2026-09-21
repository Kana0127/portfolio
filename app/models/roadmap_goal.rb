class RoadmapGoal < ApplicationRecord
  # ロードマップゴールは「2〜6か月の中期目標」として扱う
  MIN_DURATION_MONTHS = 2
  MAX_DURATION_MONTHS = 6

  belongs_to :user
  belongs_to :category

  has_many :monthly_goals, dependent: :destroy

  enum :status, {
    active: 0,
    achieved: 1,
    paused: 2,
    canceled: 3
  }

  # このロードマップの現在のステータスを現在のロケールで返す
  def status_label
    self.class.status_label_for(status)
  end

  # ステータスの表示ラベル（翻訳が無い場合は enum のキーをそのまま返す）
  def self.status_label_for(key)
    I18n.t("roadmap_goals.status.#{key}", default: key.to_s)
  end

  # select 用の [ラベル, value] 配列
  def self.status_options
    statuses.keys.map { |key| [ status_label_for(key), key ] }
  end

  # status の初期値は active（DB のデフォルトに依存せずモデル側で保証する）
  attribute :status, default: :active

  # <input type="month"> は "YYYY-MM" 形式で送られてくるため、
  # 月初日の Date に正規化してから代入する（月単位で扱うゴールのため）
  def start_month=(value)
    super(normalize_month(value))
  end

  def target_month=(value)
    super(normalize_month(value))
  end

  validates :title, presence: true
  validates :start_month, presence: true
  validates :target_month, presence: true
  validates :status, presence: true

  validate :target_month_after_start_month
  validate :duration_within_range

  private

  # "2026-04" / "2026-04-15" / Date いずれを受けても、その月の初日 Date を返す。
  # パースできない値はそのまま返し、presence バリデーションに委ねる。
  def normalize_month(value)
    return value if value.blank?
    return value.beginning_of_month if value.respond_to?(:beginning_of_month)

    str = value.to_s
    # <input type="month"> の "YYYY-MM" は年月の頭2要素として解釈する
    if (match = str.match(/\A(\d{4})-(\d{1,2})/))
      return Date.new(match[1].to_i, match[2].to_i, 1)
    end

    Date.parse(str).beginning_of_month
  rescue ArgumentError, TypeError, Date::Error
    value
  end

  def target_month_after_start_month
    return if start_month.blank? || target_month.blank?

    if target_month < start_month
      errors.add(:target_month, :before_start_month)
    end
  end

  # 期間は日数ではなく「年月の差」で判定する（月単位の中期目標のため）
  def duration_within_range
    return if start_month.blank? || target_month.blank?
    return if target_month < start_month

    if month_difference < MIN_DURATION_MONTHS
      errors.add(:target_month, :duration_too_short, count: MIN_DURATION_MONTHS)
    elsif month_difference > MAX_DURATION_MONTHS
      errors.add(:target_month, :duration_too_long, count: MAX_DURATION_MONTHS)
    end
  end

  def month_difference
    (target_month.year * 12 + target_month.month) -
      (start_month.year * 12 + start_month.month)
  end
end
