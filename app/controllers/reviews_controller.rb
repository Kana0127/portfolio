class ReviewsController < ApplicationController
  def index
    @today = Date.current

    base_scope = current_user.weekly_goals.includes(:weekly_review, :monthly_goal)

    # 今週の週目標：start_date が「今日-6日 〜 今日」の範囲（今日が start_date..start_date+6 に含まれる週目標）
    @current_weekly_goals = base_scope.where(start_date: (@today - 6.days)..@today)
                                      .order(:start_date, :week_number)
                                      .to_a

    # 先週の週目標：start_date が「今日-13日 〜 今日-7日」の範囲（先週のうち今日と同じ曜日に開始したもの）
    @last_weekly_goals = base_scope.where(start_date: (@today - 13.days)..(@today - 7.days))
                                   .order(:start_date, :week_number)
                                   .to_a

    # 今週のふりかえりを促すのは「土曜日」のみ。
    # 日曜になると新しい週が始まり、これまでの今週は @last_weekly_goals に降りるため
    # そちらの「先週のふりかえりをしましょう」案内に引き継がれる。
    @encourage_current_review = @today.saturday?
  end
end
