module MonthlyGoalsHelper
  # ロードマップの終了月と基準月（既定は今月）を月単位で比較し、
  # 残り期間を日本語ラベルで返す。
  #   終了月が先  → "残り6か月"
  #   終了月が今月 → "今月まで"
  #   終了月が過去 → "期間終了"
  def roadmap_remaining_label(roadmap_goal, today: Date.current)
    months = roadmap_remaining_months(roadmap_goal, today: today)
    return nil if months.nil?

    if months.positive?
      "残り#{months}か月"
    elsif months.zero?
      "今月まで"
    else
      "期間終了"
    end
  end

  # 基準月から終了月までの月数差を返す（終了月が過去なら負の値）。
  # target_month が未設定なら nil。
  def roadmap_remaining_months(roadmap_goal, today: Date.current)
    target_month = roadmap_goal&.target_month
    return nil if target_month.blank?

    current_month = today.beginning_of_month
    (target_month.year * 12 + target_month.month) -
      (current_month.year * 12 + current_month.month)
  end
end
