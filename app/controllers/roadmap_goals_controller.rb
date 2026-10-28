
class RoadmapGoalsController < ApplicationController

  # show / edit / update / destroy の前に
  # 対象のロードマップ目標を取得する
  before_action :set_roadmap_goal,
                only: %i[show edit update destroy]


  # ============================================================
  # ロードマップ目標一覧
  # ============================================================

  def index

    # ============================================================
    # 【今回追加】今月・来月の基準日
    # ============================================================

    current_month_start = Date.current.beginning_of_month
    next_month_start = Date.current.next_month.beginning_of_month


    # ============================================================
    # ① 今月に該当するロードマップ目標
    #
    # ・開始月が今月以前
    # ・達成予定月が今月以降
    #
    # 例：10月〜翌年2月のロードマップ
    # → 10月タブに表示
    # ============================================================

    @roadmap_goals =
      current_user.roadmap_goals
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
                  .order(created_at: :desc)


    # ============================================================
    # ② 来月に該当するロードマップ目標
    #
    # ・開始月が来月以前
    # ・達成予定月が来月以降
    #
    # 今月から継続しているロードマップも含む
    # ============================================================

    @next_roadmap_goals =
      current_user.roadmap_goals
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
                  .order(created_at: :desc)


    # ============================================================
    # ③ 今月のロードマップに紐づく
    #    今月の月目標
    #
    # {
    #   1 => [MonthlyGoal, MonthlyGoal],
    #   2 => [MonthlyGoal]
    # }
    #
    # キーはroadmap_goal.id
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
    # ④ 来月のロードマップに紐づく
    #    来月の月目標
    # ============================================================

    @next_roadmap_monthly_goals =
      @next_roadmap_goals.each_with_object({}) do |roadmap, hash|

        next_month_goals =
          roadmap.monthly_goals.select do |goal|
            goal.target_month == next_month_start
          end

        hash[roadmap.id] =
          next_month_goals
            .sort_by(&:created_at)
            .reverse
      end


    # ============================================================
    # ⑤ 【今回追加】どちらのタブを表示するか判定
    #
    # period=this → 今月
    # period=next → 来月
    #
    # 指定がなければ今月
    # ============================================================

    @period =
      if %w[this next].include?(params[:period])
        params[:period]
      else
        "this"
      end


    # ============================================================
    # ⑥ 選択された月を決定
    # ============================================================

    @selected_month =
      if @period == "this"
        current_month_start
      else
        next_month_start
      end


    # ============================================================
    # ⑦ 選択中のタブに応じて
    #    表示するロードマップ・月目標を決定
    # ============================================================

    if @period == "this"

      # 今月のロードマップ目標
      @selected_roadmap_goals = @roadmap_goals

      # 今月のロードマップに紐づく月目標
      @selected_roadmap_monthly_goals =
        @roadmap_monthly_goals

    else

      # 来月のロードマップ目標
      @selected_roadmap_goals = @next_roadmap_goals

      # 来月のロードマップに紐づく月目標
      @selected_roadmap_monthly_goals =
        @next_roadmap_monthly_goals

    end

  end


  # ============================================================
  # ロードマップ目標 新規作成画面
  # ============================================================

  def new

    @roadmap_goal =
      current_user.roadmap_goals.build

    @categories = Category.order(:id)

    # 開始月は今月を初期選択
    @start_period = "this"

    # 達成までの期間は2か月後を初期選択
    @duration_months =
      RoadmapGoal::MIN_DURATION_MONTHS.to_s

  end


  # ============================================================
  # ロードマップ目標 作成
  #
  # 直接createにPOSTされた場合の処理
  # ============================================================

  def create

    # ① Viewの選択値を日付に変換し、
    #    ロードマップ目標のインスタンスを作成

    selection_valid = build_new_roadmap_goal_from_params

    # ② DBに保存

    if selection_valid && @roadmap_goal.save

      flash[:notice] =
        "ロードマップ目標を作成しました"

      redirect_to roadmap_goal_path(@roadmap_goal)

    else
      render_new_with_error
    end

  end


  # ============================================================
  # ロードマップ目標 詳細画面
  # ============================================================

  def show
  end


  # ============================================================
  # 新規作成フロー①
  #
  # ロードマップ基本情報入力
  #         ↓
  # 入力値を検証
  #         ↓
  # セッションに一時保存
  #         ↓
  # 月目標設定画面へ
  # ============================================================

  def monthly_goals_setup

    # ① Viewの選択値を日付に変換
    selection_valid = build_new_roadmap_goal_from_params

    # ② 入力内容を検証
    unless selection_valid && @roadmap_goal.valid?
      render_new_with_error
      return
    end

    # ③ DBにはまだ保存せず、
    #    セッションにロードマップ情報を一時保存

    session[:roadmap_goal_draft] =
      draft_from(@roadmap_goal)

    # ④ 開始月から達成予定月までの
    #    各月の配列を生成

    @target_months =
      build_target_months(
        @roadmap_goal.start_month,
        @roadmap_goal.target_month
      )

    # ⑤ 月目標設定画面へ進む
    render :monthly_goals_setup

  end


  # ============================================================
  # 新規作成フロー②
  #
  # セッションのロードマップ情報
  #          ＋
  # 各月の月目標
  #          ↓
  # 一括保存
  # ============================================================

  def complete_creation

    # ① セッションから下書きを取得
    draft = session[:roadmap_goal_draft]

    if draft.blank?
      redirect_to new_roadmap_goal_path,
                  alert: "もう一度入力してください"
      return
    end

    # ② 下書きの開始月・達成予定月から
    #    対象となる月の一覧を作成

    @target_months =
      build_target_months(
        parse_month(draft["start_month"]),
        parse_month(draft["target_month"])
      )

    # ③ Form Objectを作成

    form = RoadmapGoalCreationForm.new(
      user: current_user,
      roadmap_attributes: draft,
      target_months: @target_months,
      monthly_titles: monthly_titles_for(@target_months)
    )

    # ④ ロードマップと月目標を一括保存

    if form.save

      session.delete(:roadmap_goal_draft)

      redirect_to roadmap_goal_path(form.roadmap_goal),
                  notice: "ロードマップ目標と月目標を作成しました"

    else

      @roadmap_goal =
        current_user.roadmap_goals.build(
          draft.slice(*ROADMAP_DRAFT_KEYS)
        )

      @form_errors = form.errors.full_messages

      flash.now[:alert] =
        "月目標を保存できませんでした"

      render :monthly_goals_setup,
             status: :unprocessable_entity

    end

  end


  # ============================================================
  # ロードマップ目標 編集画面
  # ============================================================

  def edit
    @categories = Category.order(:id)
  end


  # ============================================================
  # ロードマップ目標 更新
  # ============================================================

  def update

    if @roadmap_goal.update(roadmap_goal_params)

      redirect_to roadmap_goal_path(@roadmap_goal),
                  notice: "ロードマップ目標を更新しました"

    else

      @categories = Category.order(:id)

      flash.now[:alert] =
        "ロードマップ目標を更新できませんでした"

      render :edit,
             status: :unprocessable_entity
    end

  end


  # ============================================================
  # ロードマップ目標 削除
  # ============================================================

  def destroy

    @roadmap_goal.destroy!

    redirect_to monthly_goals_path,
                notice: "ロードマップ目標を削除しました"

  end


  private


  # ============================================================
  # セッションに保存するロードマップの属性
  # ============================================================

  ROADMAP_DRAFT_KEYS = %w[
    title
    reason
    start_month
    target_month
    category_id
    status
  ].freeze


  # ============================================================
  # 編集・更新・削除するロードマップ目標を取得
  # ============================================================

  def set_roadmap_goal

    @roadmap_goal =
      current_user.roadmap_goals
                  .includes(:category)
                  .find(params[:id])

  end


  # ============================================================
  # Strong Parameters
  # ============================================================

  def roadmap_goal_params

    params.require(:roadmap_goal)
          .permit(
            :title,
            :reason,
            :start_month,
            :target_month,
            :category_id,
            :status
          )

  end


  # ============================================================
  # 新規作成フォームの選択値を日付へ変換
  #
  # 月目標のcreateと同じ考え方
  #
  # 例：
  # start_period    = "this"
  # duration_months = "4"
  #
  # 2026年10月の場合：
  # start_month  = 2026-10-01
  # target_month = 2027-02-01
  # ============================================================

  def build_new_roadmap_goal_from_params

    # ① ユーザーが選んだ値を取得

    @start_period = params[:start_period]
    @duration_months = params[:duration_months]


    # ② ロードマップのインスタンスを作成
    #
    # 新規作成ではstart_monthとtarget_monthを
    # フォームの値から直接受け取らず、
    # 以下で計算して設定する

    @roadmap_goal =
      current_user.roadmap_goals.build(
        roadmap_goal_params.except(
          :start_month,
          :target_month
        )
      )


    # ③ 開始月の選択値をチェック

    unless %w[this next].include?(@start_period)
      @roadmap_goal.errors.add(
        :start_month,
        :invalid
      )
    end


    # ④ 達成までの期間をチェック

    valid_durations =
      (RoadmapGoal::MIN_DURATION_MONTHS..
       RoadmapGoal::MAX_DURATION_MONTHS).map(&:to_s)

    unless valid_durations.include?(@duration_months)
      @roadmap_goal.errors.add(
        :target_month,
        :invalid
      )
    end


    # ⑤ 不正な選択値があれば処理を終了

    return false if @roadmap_goal.errors.any?


    # ⑥ 開始月を具体的な日付に変換

    start_month =
      if @start_period == "this"
        Date.current.beginning_of_month
      else
        Date.current.next_month.beginning_of_month
      end


    # ⑦ 達成予定月を計算

    target_month =
      start_month.advance(
        months: @duration_months.to_i
      )


    # ⑧ Modelの属性にセット

    @roadmap_goal.start_month = start_month
    @roadmap_goal.target_month = target_month

    true

  end


  # ============================================================
  # 新規作成フォームをエラー付きで再表示
  # ============================================================

  def render_new_with_error

    @categories = Category.order(:id)

    flash.now[:alert] =
      "ロードマップ目標を作成できませんでした"

    render :new,
           status: :unprocessable_entity

  end


  # ============================================================
  # 開始月〜達成予定月の月初Date配列を生成
  # ※開始月・達成予定月を含む
  # ============================================================

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


  # ============================================================
  # セッション保存用の下書きデータを作成
  # ============================================================

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


  # ============================================================
  # 月目標の入力値を取得
  #
  # サーバーで生成した対象月のみ使用
  # ============================================================

  def monthly_titles_for(target_months)

    submitted = params[:monthly_goals] || {}

    target_months.index_with do |month|
      submitted.dig(month.to_s, :title)
    end

  end


  # ============================================================
  # 文字列をDate型に変換
  # ============================================================

  def parse_month(value)

    Date.parse(value.to_s)

  rescue ArgumentError, TypeError, Date::Error
    nil

  end

end
