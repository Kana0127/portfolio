class RoadmapGoalsController < ApplicationController
  before_action :set_roadmap_goal, only: %i[show edit update destroy]

  def index
    # 本人のロードマップ目標のみ。作成の新しい順で表示
    @roadmap_goals = current_user.roadmap_goals
                                 .includes(:category)
                                 .order(created_at: :desc)
  end

  def new
    @roadmap_goal = current_user.roadmap_goals.build
    @categories = Category.order(:id)
  end

  def create
    @roadmap_goal = current_user.roadmap_goals.build(roadmap_goal_params)

    if @roadmap_goal.save
      flash[:notice] = "ロードマップ目標を作成しました"
      redirect_to roadmap_goal_path(@roadmap_goal)
    else
      @categories = Category.order(:id)
      flash.now[:alert] = "ロードマップ目標を作成できませんでした"
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit
    @categories = Category.order(:id)
  end

  def update
    if @roadmap_goal.update(roadmap_goal_params)
      redirect_to roadmap_goal_path(@roadmap_goal), notice: "ロードマップ目標を更新しました"
    else
      @categories = Category.order(:id)
      flash.now[:alert] = "ロードマップ目標を更新できませんでした"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @roadmap_goal.destroy!
    redirect_to monthly_goals_path, notice: "ロードマップ目標を削除しました"
  end

  private

  # 本人のロードマップ目標のみ取得。他ユーザーのIDは RecordNotFound → 404
  def set_roadmap_goal
    @roadmap_goal = current_user.roadmap_goals.includes(:category).find(params[:id])
  end

  # user_id はフォームから受け取らない（current_user 経由で紐づける）
  def roadmap_goal_params
    params.require(:roadmap_goal)
          .permit(:title, :reason, :start_month, :target_month, :category_id, :status)
  end
end
