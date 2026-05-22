class MonthlyGoalsController < ApplicationController
  NEXT_MONTH_AVAILABLE_DAY = 25

  def index
    @monthly_goals = current_user.monthly_goals
                                 .includes(:category)
                                 .order(target_month: :desc, created_at: :desc)
    @next_month_available = next_month_available?
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

  private

  def monthly_goal_params
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
