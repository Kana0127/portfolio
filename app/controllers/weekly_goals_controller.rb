class WeeklyGoalsController < ApplicationController
  before_action :set_monthly_goal

  def new
    @weekly_goal = @monthly_goal.weekly_goals.build
    @start_date_options = build_start_date_options
  end

  def create
    @weekly_goal = @monthly_goal.weekly_goals.build(weekly_goal_params)

    if @weekly_goal.save
      flash[:notice] = "週目標を作成しました"
      redirect_to monthly_goals_path
    else
      @start_date_options = build_start_date_options
      flash.now[:alert] = "週目標を作成できませんでした"
      render :new, status: :unprocessable_entity
    end
  end

  private

  # 本人の月目標から取得。他人の月目標IDをURLに入れても RecordNotFound → 404
  def set_monthly_goal
    @monthly_goal = current_user.monthly_goals.find(params[:monthly_goal_id])
  end

  # week_number / monthly_goal_id はフォームから受け取らない
  def weekly_goal_params
    params.require(:weekly_goal).permit(:title, :start_date)
  end

  # 「第N週：M月D日（曜）」というラベルで select 用の [label, value] 配列を作る
  def build_start_date_options
    wday_names = %w[日 月 火 水 木 金 土]
    WeeklyGoal.start_date_candidates(@monthly_goal.target_month).map.with_index(1) do |date, week_num|
      label = "第#{week_num}週：#{date.strftime('%-m月%-d日')}（#{wday_names[date.wday]}）"
      [ label, date.to_s ]
    end
  end
end
