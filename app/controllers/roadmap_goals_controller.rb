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

  # 新規作成フロー①：入力値を検証し、問題なければセッションに一時保存して月目標設定画面へ
  def monthly_goals_setup
    @roadmap_goal = current_user.roadmap_goals.build(roadmap_goal_params)

    unless @roadmap_goal.valid?
      @categories = Category.order(:id)
      flash.now[:alert] = "ロードマップ目標を作成できませんでした"
      render :new, status: :unprocessable_entity and return
    end

    # ロードマップ入力値をセッションに一時保存（この時点では DB 保存しない）
    session[:roadmap_goal_draft] = draft_from(@roadmap_goal)

    @target_months = build_target_months(@roadmap_goal.start_month, @roadmap_goal.target_month)
    render :monthly_goals_setup
  end

  # 新規作成フロー②：セッションの下書き＋各月の入力から、ロードマップと月目標を一括保存
  def complete_creation
    draft = session[:roadmap_goal_draft]
    redirect_to new_roadmap_goal_path, alert: "もう一度入力してください" and return if draft.blank?

    @target_months = build_target_months(
      parse_month(draft["start_month"]),
      parse_month(draft["target_month"])
    )

    form = RoadmapGoalCreationForm.new(
      user: current_user,
      roadmap_attributes: draft,
      target_months: @target_months,
      monthly_titles: monthly_titles_for(@target_months)
    )

    if form.save
      session.delete(:roadmap_goal_draft)
      redirect_to roadmap_goal_path(form.roadmap_goal), notice: "ロードマップ目標と月目標を作成しました"
    else
      @roadmap_goal = current_user.roadmap_goals.build(draft.slice(*ROADMAP_DRAFT_KEYS))
      @form_errors = form.errors.full_messages
      flash.now[:alert] = "月目標を保存できませんでした"
      render :monthly_goals_setup, status: :unprocessable_entity
    end
  end

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

  # セッションに保存する RoadmapGoal の下書きキー
  ROADMAP_DRAFT_KEYS = %w[title reason start_month target_month category_id status].freeze

  # 本人のロードマップ目標のみ取得。他ユーザーのIDは RecordNotFound → 404
  def set_roadmap_goal
    @roadmap_goal = current_user.roadmap_goals.includes(:category).find(params[:id])
  end

  # user_id はフォームから受け取らない（current_user 経由で紐づける）
  def roadmap_goal_params
    params.require(:roadmap_goal)
          .permit(:title, :reason, :start_month, :target_month, :category_id, :status)
  end

  # 開始月〜終了月（両端含む）の月初 Date 配列を生成する
  def build_target_months(start_month, target_month)
    return [] if start_month.blank? || target_month.blank?

    current_month = start_month.beginning_of_month
    last_month = target_month.beginning_of_month
    months = []

    while current_month <= last_month
      months << current_month
      current_month = current_month.next_month
    end

    months
  end

  # 検証済みの RoadmapGoal からセッション保存用ハッシュを作る（月は文字列 "YYYY-MM-DD" で保持）
  def draft_from(roadmap_goal)
    {
      "title"        => roadmap_goal.title,
      "reason"       => roadmap_goal.reason,
      "start_month"  => roadmap_goal.start_month&.to_s,
      "target_month" => roadmap_goal.target_month&.to_s,
      "category_id"  => roadmap_goal.category_id,
      "status"       => roadmap_goal.status
    }
  end

  # クライアントの月キーは信用せず、サーバ側で生成した target_months だけを対象に
  # { Date => 入力タイトル } を組み立てる
  def monthly_titles_for(target_months)
    submitted = params[:monthly_goals] || {}
    target_months.index_with do |month|
      submitted.dig(month.to_s, :title)
    end
  end

  def parse_month(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError, Date::Error
    nil
  end
end
