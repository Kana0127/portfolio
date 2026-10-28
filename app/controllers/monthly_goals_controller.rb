
class MonthlyGoalsController < ApplicationController

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
    # 今月・来月の基準日
    # ============================================================

    current_month_start = Date.current.beginning_of_month
    next_month_start = Date.current.next_month.beginning_of_month

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
    # ③ 各ロードマップに紐づく今月の月目標
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
    # ④ 今月の単体月目標
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
    # 来月の単体月目標
    # ============================================================

    @next_month_goals =
      current_user.monthly_goals
                  .where(
                    roadmap_goal_id: nil
                  )
                  .where(
                    target_month: next_month_start
                  )
                  .includes(
                    :category,
                    :weekly_goals
                  )
                  .order(
                    created_at: :desc
                  )


    # ============================================================
    # ⑤ 今週の単体週目標
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
    # ⑧ 月目標作成を促す表示の判定
    # ============================================================

    @show_current_month_prompt =
      !@current_month_goal_registered

    @show_next_month_prompt =
      !@next_month_goal_registered


    # ============================================================
    # ⑨【今回追加】今月・来月のタブを判定
    #
    # period=this → 今月
    # period=next → 来月
    # 指定がなければ今月
    # ============================================================

    @period =
      if %w[this next].include?(params[:period])
        params[:period]
      else
        "this"
      end


    # ============================================================
    # ⑩【今回追加】表示対象の月を決定
    # ============================================================

    @selected_month =
      if @period == "this"
        current_month_start
      else
        next_month_start
      end


    # ============================================================
    # ⑪【今回追加】選択中のタブに応じて
    # 表示するロードマップ・月目標を切り替える
    # ============================================================

    if @period == "this"

      # --------------------------------------------
      # 今月の場合
      #
      # すでに取得済みのデータをそのまま使用
      # --------------------------------------------

      @selected_roadmap_goals = @roadmap_goals

      @selected_roadmap_monthly_goals =
        @roadmap_monthly_goals

      @selected_monthly_goals = @monthly_goals

    else

      # --------------------------------------------
      # 来月の場合
      #
      # 来月がロードマップ期間に含まれる目標を取得
      # --------------------------------------------

      @selected_roadmap_goals =
        current_user.roadmap_goals
                    .active
                    .where(
                      start_month: ..next_month_start
                    )
                    .where(
                      target_month: next_month_start..
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


      # --------------------------------------------
      # 来月のロードマップに紐づく
      # 来月の月目標を取得
      # --------------------------------------------

      @selected_roadmap_monthly_goals =
        @selected_roadmap_goals.each_with_object({}) do |roadmap, hash|

          next_month_goals =
            roadmap.monthly_goals.select do |goal|
              goal.target_month == next_month_start
            end

          hash[roadmap.id] =
            next_month_goals
              .sort_by(&:created_at)
              .reverse
        end


      # --------------------------------------------
      # 来月の単体月目標
      #
      # すでに取得済みのデータを使用
      # --------------------------------------------

      @selected_monthly_goals = @next_month_goals

    end

  end


  # ============================================================
  # 月目標 新規作成画面
  # ============================================================

  def new
    @monthly_goal = current_user.monthly_goals.build
    @categories = Category.order(:id)
    @target_month_param = "this"
  end


  # ============================================================
  # 月目標 作成
  # ============================================================

  def create

    # ① ユーザーが選んだ値を取得
    period = params[:target_month]

    # ② 想定外の値を拒否
    unless %w[this next].include?(period)
      return head :unprocessable_entity
    end

    # ③ 選択値を日付に変換
    target_month =
      if period == "this"
        Date.current.beginning_of_month
      else
        Date.current.next_month.beginning_of_month
      end

    # ④ 月目標のインスタンスを作成
    @monthly_goal =
      current_user.monthly_goals.build(
        monthly_goal_params
      )

    # ⑤ 対象月をセット
    @monthly_goal.target_month = target_month

    # ⑥ DBに保存
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
    @categories = Category.order(:id)
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

      @categories = Category.order(:id)

      flash.now[:alert] =
        "月目標を更新できませんでした"

      render :edit, status: :unprocessable_entity
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

    @categories = Category.order(:id)

    @target_month_param = params[:target_month]

    flash.now[:alert] =
      "月目標を作成できませんでした"

    render(
      :new,
      status: :unprocessable_entity
    )
  end


  # ============================================================
  # 月目標フォームで選択できるロードマップ一覧
  # ============================================================

  def set_roadmap_goals

    @roadmap_goals =
      current_user.roadmap_goals
                  .order(created_at: :desc)
  end

end
