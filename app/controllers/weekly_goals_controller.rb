class WeeklyGoalsController < ApplicationController
  # MonthlyGoalsController と同じ「来月解禁日」のしきい値を使う
  NEXT_MONTH_AVAILABLE_DAY = 25

  before_action :set_monthly_goal
  before_action :restrict_next_month_weekly_goal_creation, only: %i[new create]
  before_action :set_weekly_goal, only: %i[edit update destroy]

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

  def edit
    @start_date_options = build_start_date_options
  end

  def update
    if @weekly_goal.update(weekly_goal_params)
      flash[:notice] = "週目標を更新しました"
      redirect_to monthly_goals_path
    else
      @start_date_options = build_start_date_options
      flash.now[:alert] = "週目標を更新できませんでした"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @weekly_goal.destroy!
    flash[:notice] = "週目標を削除しました"
    redirect_to monthly_goals_path
  end

  private

  # 本人の月目標から取得。他人の月目標IDをURLに入れても RecordNotFound → 404
  def set_monthly_goal
    @monthly_goal = current_user.monthly_goals.find(params[:monthly_goal_id])
  end

  # 必ず @monthly_goal.weekly_goals から取得。
  # 他人の monthly_goal の配下にある週目標IDを直打ちしても RecordNotFound になる。
  def set_weekly_goal
    @weekly_goal = @monthly_goal.weekly_goals.find(params[:id])
  end

  # 来月の月目標に対する週目標は、25日以降のみ作成できるようにする。
  # new / create の前段で動かすことで、URL直打ち・POST直打ちのどちらも弾く。
  def restrict_next_month_weekly_goal_creation
    return unless next_month_goal?
    return if next_month_available?

    redirect_to monthly_goals_path, alert: "来月の週目標は毎月25日以降に作成できます"
  end

  def next_month_goal?
    @monthly_goal.target_month == Date.current.next_month.beginning_of_month
  end

  def next_month_available?
    Date.current.day >= NEXT_MONTH_AVAILABLE_DAY
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
