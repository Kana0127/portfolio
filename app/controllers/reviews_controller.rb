class ReviewsController < ApplicationController
  def index
    @today = Date.current

    # 今週の週目標：current_user.weekly_goals（has_many :through 経由）から
    # start_date が「今日-6日 〜 今日」の範囲にあるもの。
    # weekly_review / monthly_goal を eager load して N+1 を避ける。
    @current_weekly_goals = current_user.weekly_goals
                                        .includes(:weekly_review, :monthly_goal)
                                        .where(start_date: (@today - 6.days)..@today)
                                        .order(:start_date, :week_number)
  end
end
