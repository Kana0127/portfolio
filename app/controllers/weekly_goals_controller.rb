class WeeklyGoalsController < ApplicationController
  # MonthlyGoalsController と同じ「来月解禁日」のしきい値
  NEXT_MONTH_AVAILABLE_DAY = 25

  before_action :set_monthly_goal
  before_action :set_weekly_goal, only: %i[edit update destroy]
  before_action :restrict_next_month_weekly_goal_creation, only: %i[new create]

  def new
    @weekly_goal = current_user.weekly_goals.build

    apply_monthly_goal_defaults
    prepare_form_data
  end

  def create
    @weekly_goal = current_user.weekly_goals.build(weekly_goal_params)

    apply_monthly_goal_defaults

    if @weekly_goal.save
      redirect_to monthly_goals_path, notice: "週目標を作成しました"
    else
      prepare_form_data
      flash.now[:alert] = "週目標を作成できませんでした"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_form_data
  end

  def update
    if @weekly_goal.update(weekly_goal_params)
      redirect_to monthly_goals_path, notice: "週目標を更新しました"
    else
      prepare_form_data
      flash.now[:alert] = "週目標を更新できませんでした"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @weekly_goal.destroy!

    redirect_to monthly_goals_path, notice: "週目標を削除しました"
  end

  private

  # monthly_goal_id がある場合だけ月目標を取得する。
  # Standalone WeeklyGoal の場合は @monthly_goal = nil のまま進む。
  def set_monthly_goal
    return if params[:monthly_goal_id].blank?

    @monthly_goal =
      current_user.monthly_goals.find(params[:monthly_goal_id])
  end

  # 編集・更新・削除するWeeklyGoalを取得する。
  #
  # MonthlyGoal経由
  # → そのMonthlyGoalに属するWeeklyGoalだけ取得
  #
  # Standalone
  # → current_userのmonthly_goal_id=nilのWeeklyGoalだけ取得
  def set_weekly_goal
    @weekly_goal =
      if @monthly_goal
        @monthly_goal.weekly_goals
                     .where(user: current_user)
                     .find(params[:id])
      else
        current_user.weekly_goals
                    .where(monthly_goal_id: nil)
                    .find(params[:id])
      end
  end

  # MonthlyGoal経由の場合だけ
  # monthly_goal と category を引き継ぐ。
  def apply_monthly_goal_defaults
    return unless @monthly_goal

    @weekly_goal.monthly_goal = @monthly_goal
    @weekly_goal.category = @monthly_goal.category
  end

  # new / edit / validation error時のフォーム表示に必要なデータを準備する。
  def prepare_form_data
    @target_month =
      if @monthly_goal
        @monthly_goal.target_month
      elsif @weekly_goal.persisted? && @weekly_goal.start_date.present?
        @weekly_goal.start_date.beginning_of_month
      else
        Date.current.beginning_of_month
      end

    # Standaloneの場合だけカテゴリー選択が必要
    @categories = Category.order(:id) unless @monthly_goal

    @start_date_options = build_start_date_options
  end

  # 来月のMonthlyGoalに紐づくWeeklyGoalは25日以降のみ作成可能。
  # Standalone WeeklyGoalではこのチェックを行わない。
  def restrict_next_month_weekly_goal_creation
    return unless @monthly_goal
    return unless next_month_goal?
    return if next_month_available?

    redirect_to(
      monthly_goals_path,
      alert: "来月の週目標は毎月25日以降に作成できます"
    )
  end

  def next_month_goal?
    @monthly_goal.target_month ==
      Date.current.next_month.beginning_of_month
  end

  def next_month_available?
    Date.current.day >= NEXT_MONTH_AVAILABLE_DAY
  end

  # MonthlyGoal経由の場合はcategoryをMonthlyGoalから引き継ぐため
  # category_idをフォームから受け取らない。
  #
  # Standaloneの場合だけcategory_idを受け取る。
  def weekly_goal_params
    permitted_params = %i[title start_date]

    permitted_params << :category_id unless @monthly_goal

    params.require(:weekly_goal).permit(*permitted_params)
  end

  # 対象月から「第N週：M月D日（曜）」を作る。
  def build_start_date_options
    wday_names = %w[ 日 月 火 水 木 金 土 ]

    WeeklyGoal.start_date_candidates(@target_month)
              .map.with_index(1) do |date, week_num|
      label =
        "第#{week_num}週：" \
        "#{date.strftime('%-m月%-d日')}" \
        "（#{wday_names[date.wday]}）"

      [label, date.to_s]
    end
  end
end