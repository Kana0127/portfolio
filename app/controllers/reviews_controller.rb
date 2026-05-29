class ReviewsController < ApplicationController
  def index
    @today = Date.current

    # ========== 週次振り返り（issue23-24） ==========
    base_scope = current_user.weekly_goals.includes(:weekly_review, :monthly_goal)

    # 今週の週目標：start_date が「今日-6日 〜 今日」の範囲
    @current_weekly_goals = base_scope.where(start_date: (@today - 6.days)..@today)
                                      .order(:start_date, :week_number)
                                      .to_a

    # 先週の週目標：start_date が「今日-13日 〜 今日-7日」の範囲
    @last_weekly_goals = base_scope.where(start_date: (@today - 13.days)..(@today - 7.days))
                                   .order(:start_date, :week_number)
                                   .to_a

    # 今週のふりかえりを促すのは「土曜日」のみ
    @encourage_current_review = @today.saturday?

    # ========== 月次振り返り（issue26-27） ==========
    current_month = @today.beginning_of_month
    last_month    = (@today - 1.month).beginning_of_month

    # 先月の月目標：未登録なら常に「先月の月目標に対して振り返りを行いましょう」の促進対象
    @last_monthly_goals = current_user.monthly_goals
                                      .includes(:monthly_review)
                                      .where(target_month: last_month)
                                      .order(created_at: :desc)
                                      .to_a

    # 今月の月目標：25日以降のみ振り返り促進対象
    @current_monthly_goals = current_user.monthly_goals
                                         .includes(:monthly_review)
                                         .where(target_month: current_month)
                                         .order(created_at: :desc)
                                         .to_a

    # 今月の月次振り返りを促すのは「25日以降」のみ
    @encourage_current_month_review = @today.day >= 25
  end
end
