class DailyRecord < ApplicationRecord
  belongs_to :weekly_goal

  # ◎ / ○ / × の3段階を integer で持つ
  enum :status, {
    perfect: 0,  # ◎ しっかりできた
    good:    1,  # ○ 少しできた
    bad:     2   # × できなかった
  }

  validates :record_date, presence: true, uniqueness: { scope: :weekly_goal_id }
  validates :status, presence: true

  # ビュー表示用に絵文字を返すヘルパー
  def status_symbol
    case status
    when "perfect" then "◎"
    when "good"    then "○"
    when "bad"     then "×"
    end
  end

  # ビュー表示用に日本語ラベルを返す
  def status_label
    case status
    when "perfect" then "よくできた"
    when "good"    then "できた"
    when "bad"     then "おやすみ"
    end
  end
end
