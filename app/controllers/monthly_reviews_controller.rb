class MonthlyReviewsController < ApplicationController
  before_action :set_monthly_goal

  def new
    # 二重登録防止：既に振り返りがあれば show にリダイレクト
    if @monthly_goal.monthly_review.present?
      redirect_to monthly_goal_monthly_review_path(@monthly_goal) and return
    end

    @monthly_review = @monthly_goal.build_monthly_review
  end

  def create
    # POST 直打ち対策：既に振り返りがあれば show にリダイレクト
    if @monthly_goal.monthly_review.present?
      redirect_to monthly_goal_monthly_review_path(@monthly_goal),
                  alert: "この月目標の振り返りは登録済みです" and return
    end

    @monthly_review = @monthly_goal.build_monthly_review(monthly_review_params)
    if @monthly_review.save
      flash[:notice] = "月次振り返りを登録しました"
      redirect_to monthly_goal_monthly_review_path(@monthly_goal)
    else
      flash.now[:alert] = "月次振り返りを登録できませんでした"
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @monthly_review = @monthly_goal.monthly_review
    # 未登録なら登録画面へ
    redirect_to new_monthly_goal_monthly_review_path(@monthly_goal) and return unless @monthly_review
  end

  private

  # 本人の月目標のみ取得。他人の monthly_goal_id を直打ちしても RecordNotFound（404）。
  def set_monthly_goal
    @monthly_goal = current_user.monthly_goals.find(params[:monthly_goal_id])
  end

  # monthly_goal_id はフォームから受け取らない
  def monthly_review_params
    params.require(:monthly_review).permit(:achievement_rate, :good_point, :improvement_point, :memo)
  end
end
