class WeeklyReviewsController < ApplicationController
  before_action :set_weekly_goal

  def new
    # 二重登録防止：既に振り返りがあれば show にリダイレクト
    if @weekly_goal.weekly_review.present?
      redirect_to weekly_goal_weekly_review_path(@weekly_goal) and return
    end

    @weekly_review = @weekly_goal.build_weekly_review
  end

  def create
    # POST 直打ち対策：すでに振り返りがあれば show にリダイレクト
    if @weekly_goal.weekly_review.present?
      redirect_to weekly_goal_weekly_review_path(@weekly_goal),
                  alert: "この週目標の振り返りは登録済みです" and return
    end

    @weekly_review = @weekly_goal.build_weekly_review(weekly_review_params)
    if @weekly_review.save
      flash[:notice] = "週次振り返りを登録しました"
      redirect_to weekly_goal_weekly_review_path(@weekly_goal)
    else
      flash.now[:alert] = "週次振り返りを登録できませんでした"
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @weekly_review = @weekly_goal.weekly_review
    # 未登録なら登録画面へ
    redirect_to new_weekly_goal_weekly_review_path(@weekly_goal) and return unless @weekly_review
  end

  private

  # 本人の週目標だけを取得。User → MonthlyGoal → WeeklyGoal の has_many :through で
  # 他人の weekly_goal_id を直打ちしても RecordNotFound（404）になる。
  def set_weekly_goal
    @weekly_goal = current_user.weekly_goals.find(params[:weekly_goal_id])
  end

  # weekly_goal_id はフォームから受け取らない
  def weekly_review_params
    params.require(:weekly_review).permit(:achievement_rate, :good_point, :improvement_point, :memo)
  end
end
