class MonthlyGoalsController < ApplicationController
  NEXT_MONTH_AVAILABLE_DAY = 25

  before_action :set_monthly_goal, only: %i[edit update destroy]

  def index
    @monthly_goals = current_user.monthly_goals
                                 .includes(:category)
                                 .order(target_month: :desc, created_at: :desc)
    @next_month_available = next_month_available?

    # 今月・来月の月目標が本人ぶんで存在するか判定
    current_month_start = Date.current.beginning_of_month
    next_month_start    = Date.current.next_month.beginning_of_month
    @current_month_goal_registered = current_user.monthly_goals.exists?(target_month: current_month_start)
    @next_month_goal_registered    = current_user.monthly_goals.exists?(target_month: next_month_start)

    # ビュー側の表示判定に使う
    @show_current_month_prompt = !@current_month_goal_registered
    @show_next_month_prompt    = @next_month_available && !@next_month_goal_registered
  end

  def new
    if next_month_request? && !next_month_available?
      redirect_to monthly_goals_path, alert: "来月の目標は毎月25日以降に作成できます" and return
    end

    @monthly_goal = current_user.monthly_goals.build
    @categories = Category.order(:id)
    @target_month_date = resolve_target_month
    @target_month_param = current_target_month_param
  end

  def create
    @monthly_goal = current_user.monthly_goals.build(monthly_goal_params)
    @monthly_goal.target_month = resolve_target_month

    if next_month_request? && !next_month_available?
      @monthly_goal.errors.add(:base, "来月の目標は毎月25日以降に作成できます")
      render_new_with_error and return
    end

    if @monthly_goal.save
      flash[:notice] = "月目標を作成しました"
      redirect_to monthly_goals_path
    else
      render_new_with_error
    end
  end

  def edit
    @categories = Category.order(:id)
  end

  def update
    if @monthly_goal.update(monthly_goal_params)
      flash[:notice] = "月目標を更新しました"
      redirect_to monthly_goals_path
    else
      @categories = Category.order(:id)
      flash.now[:alert] = "月目標を更新できませんでした"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monthly_goal.destroy!
    flash[:notice] = "月目標を削除しました"
    redirect_to monthly_goals_path
  end

  private

  # 本人の月目標だけを取得する。他ユーザーのIDを指定された場合は
  # RecordNotFound → Rails が 404 を返すので情報が漏れない。
  def set_monthly_goal
    @monthly_goal = current_user.monthly_goals.find(params[:id])
  end

  def monthly_goal_params
    # user_id / target_month は Strong Parameters で受け取らない
    params.require(:monthly_goal).permit(:title, :category_id, :goal_kind)
  end

  def render_new_with_error
    @categories = Category.order(:id)
    @target_month_date = resolve_target_month
    @target_month_param = current_target_month_param
    flash.now[:alert] = "月目標を作成できませんでした"
    render :new, status: :unprocessable_entity
  end

  def current_target_month_param
    params[:target_month] == "next" ? "next" : "this"
  end

  def next_month_request?
    current_target_month_param == "next"
  end

  def next_month_available?
    Date.current.day >= NEXT_MONTH_AVAILABLE_DAY
  end

  def resolve_target_month
    if next_month_request?
      Date.current.next_month.beginning_of_month
    else
      Date.current.beginning_of_month
    end
  end
end
