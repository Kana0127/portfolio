class MonthlyGoalsController < ApplicationController
  # 来月の月目標を作成できるようになる日
  NEXT_MONTH_AVAILABLE_DAY = 25

  # edit / update / destroy の前に対象の月目標を取得する
  before_action :set_monthly_goal, only: %i[edit update destroy]

  # new / create / edit / update では、
  # 月目標に紐づけるロードマップ目標一覧を取得する
  before_action :set_roadmap_goals, only: %i[new create edit update]

  # ============================================================
  # 目標一覧
  # ============================================================

  def index
    # ============================================================
    # 今月の基準日
    #
    # 例：
    # 2026/8/18 → 2026/8/1
    # ============================================================

    current_month_start = Date.current.beginning_of_month

    @today = Date.current

    @current_month_date = current_month_start


    # ============================================================
    # ① 現在が今月の第何週かを取得
    # ============================================================

    @current_week_number =
      WeeklyGoal.current_week_number(
        @today,
        current_month_start
      )


    # ============================================================
    # ② 今月進行中のロードマップ目標
    #
    # ・active
    # ・開始月が今月以前
    # ・終了月が今月以降
    #
    # category
    # monthly_goals
    # monthly_goal に紐づく category / weekly_goals
    # も事前読み込みする
    # ============================================================

    @roadmap_goals =
      current_user.roadmap_goals
                  .active
                  .where(
                    start_month: ..current_month_start
                  )
                  .where(
                    target_month: current_month_start..
                  )
                  .includes(:category)
                  .preload(
                    monthly_goals: [
                      :category,
                      :weekly_goals
                    ]
                  )
                  .order(
                    start_month: :asc,
                    created_at: :desc
                  )


    # ============================================================
    # ③ 各ロードマップに紐づく
    #    「今月の月目標」
    #
    # 例：
    #
    # {
    #   1 => [MonthlyGoal, MonthlyGoal],
    #   2 => [MonthlyGoal]
    # }
    #
    # 1、2 は roadmap_goal.id
    # ============================================================

    @roadmap_monthly_goals =
      @roadmap_goals.each_with_object({}) do |roadmap, hash|
        current_month_goals =
          roadmap.monthly_goals.select do |goal|
            goal.target_month == current_month_start
          end

        hash[roadmap.id] =
          current_month_goals
            .sort_by(&:created_at)
            .reverse
      end


    # ============================================================
    # ④ ロードマップに紐づかない
    #    「今月の単体月目標」
    #
    # roadmap_goal_id: nil
    #   ↓
    # ロードマップを親に持たない月目標
    #
    # target_month: current_month_start
    #   ↓
    # 今月の目標だけ
    # ============================================================

    @monthly_goals =
      current_user.monthly_goals
                  .where(
                    roadmap_goal_id: nil
                  )
                  .where(
                    target_month: current_month_start
                  )
                  .includes(
                    :category,
                    :weekly_goals
                  )
                  .order(
                    created_at: :desc
                  )


    # ============================================================
    # ⑤ 月目標に紐づかない
    #    「今週の単体週目標」
    #
    # monthly_goal_id: nil
    #   ↓
    # 月目標を親に持たない単体週目標
    #
    # さらに
    # ・今月
    # ・現在の週番号
    #
    # に一致するものだけ取得する
    # ============================================================

    @weekly_goals =
      current_user.weekly_goals
                  .where(
                    monthly_goal_id: nil
                  )
                  .where(
                    start_date:
                      current_month_start..current_month_start.end_of_month
                  )
                  .where(
                    week_number: @current_week_number
                  )
                  .includes(:category)
                  .order(
                    created_at: :desc
                  )


    # ============================================================
    # ⑥ 来月の月目標を作成できるか
    # ============================================================

    @next_month_available =
      next_month_available?


    # 来月の1日
    #
    # 例：
    # 2026/8/18 → 2026/9/1

    next_month_start =
      Date.current.next_month.beginning_of_month


    # ============================================================
    # ⑦ 今月・来月の月目標がすでに存在するか
    # ============================================================

    @current_month_goal_registered =
      current_user.monthly_goals.exists?(
        target_month: current_month_start
      )

    @next_month_goal_registered =
      current_user.monthly_goals.exists?(
        target_month: next_month_start
      )


    # ============================================================
    # ⑧ View側で
    # 「月目標を作りましょう」などを表示するための判定
    # ============================================================

    @show_current_month_prompt =
      !@current_month_goal_registered

    @show_next_month_prompt =
      @next_month_available &&
      !@next_month_goal_registered
  end


  # ============================================================
  # 月目標 新規作成画面
  # ============================================================

  def new
    # 来月の目標を作ろうとしている
    # かつ
    # まだ25日より前なら作成不可
    if next_month_request? && !next_month_available?
      redirect_to(
        monthly_goals_path,
        alert: "来月の目標は毎月25日以降に作成できます"
      )

      return
    end

    # 現在ログインしているユーザーの月目標を作る
    @monthly_goal =
      current_user.monthly_goals.build

    # フォームのカテゴリ選択肢
    @categories =
      Category.order(:id)

    # 今月 or 来月のどちらを作成するのか
    @target_month_date =
      resolve_target_month

    # View側で this / next を利用する
    @target_month_param =
      current_target_month_param
  end


  # ============================================================
  # 月目標 作成
  # ============================================================

  def create
    # current_user に紐づく月目標を作る
    @monthly_goal =
      current_user.monthly_goals.build(
        monthly_goal_params
      )

    # target_month はフォームから直接受け取らず、
    # Controller側で今月または来月を設定する
    @monthly_goal.target_month =
      resolve_target_month

    # 25日より前に来月目標を作成しようとした場合
    if next_month_request? && !next_month_available?
      @monthly_goal.errors.add(
        :base,
        "来月の目標は毎月25日以降に作成できます"
      )

      render_new_with_error

      return
    end

    if @monthly_goal.save
      flash[:notice] =
        "月目標を作成しました"

      redirect_to monthly_goals_path
    else
      render_new_with_error
    end
  end


  # ============================================================
  # 月目標 編集画面
  # ============================================================

  def edit
    @categories =
      Category.order(:id)
  end


  # ============================================================
  # 月目標 更新
  # ============================================================

  def update
    if @monthly_goal.update(monthly_goal_params)
      flash[:notice] =
        "月目標を更新しました"

      redirect_to monthly_goals_path
    else
      @categories =
        Category.order(:id)

      flash.now[:alert] =
        "月目標を更新できませんでした"

      render(
        :edit,
        status: :unprocessable_entity
      )
    end
  end


  # ============================================================
  # 月目標 削除
  # ============================================================

  def destroy
    @monthly_goal.destroy!

    flash[:notice] =
      "月目標を削除しました"

    redirect_to monthly_goals_path
  end


  private


  # ============================================================
  # 編集・更新・削除する月目標を取得
  # ============================================================

  def set_monthly_goal
    # current_user.monthly_goals から探すことで、
    # 他ユーザーの月目標を取得できないようにする
    @monthly_goal =
      current_user.monthly_goals.find(
        params[:id]
      )
  end


  # ============================================================
  # Strong Parameters
  # ============================================================

  def monthly_goal_params
    params
      .require(:monthly_goal)
      .permit(
        :title,
        :category_id,
        :goal_kind,
        :roadmap_goal_id
      )
  end


  # ============================================================
  # new画面をエラー付きで再表示
  # ============================================================

  def render_new_with_error
    @categories =
      Category.order(:id)

    @target_month_date =
      resolve_target_month

    @target_month_param =
      current_target_month_param

    flash.now[:alert] =
      "月目標を作成できませんでした"

    render(
      :new,
      status: :unprocessable_entity
    )
  end


  # ============================================================
  # URLから this / next を判定
  # ============================================================

  def current_target_month_param
    if params[:target_month] == "next"
      "next"
    else
      "this"
    end
  end


  # ============================================================
  # 月目標フォームで選択できるロードマップ一覧
  # ============================================================

  def set_roadmap_goals
    @roadmap_goals =
      current_user.roadmap_goals
                  .order(created_at: :desc)
  end


  # ============================================================
  # 来月の目標作成リクエストか
  # ============================================================

  def next_month_request?
    current_target_month_param == "next"
  end


  # ============================================================
  # 来月の月目標を作成可能か
  # ============================================================

  def next_month_available?
    Date.current.day >=
      NEXT_MONTH_AVAILABLE_DAY
  end


  # ============================================================
  # 月目標の対象月を決める
  # ============================================================

  def resolve_target_month
    if next_month_request?
      Date.current
          .next_month
          .beginning_of_month
    else
      Date.current
          .beginning_of_month
    end
  end
end