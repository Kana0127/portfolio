# ロードマップ目標と、その期間内の月目標をまとめて作成する Form Object（issue37）
#
# - RoadmapGoal を 1 件
# - 期間（開始月〜終了月）分の MonthlyGoal を複数件
# を同一トランザクションで作成する。1 件でも失敗すれば全ロールバック。
#
# セキュリティ上重要な属性（user / category / roadmap_goal / goal_kind / target_month）は
# クライアント入力を信用せず、この Form 内で確定する。
class RoadmapGoalCreationForm
  include ActiveModel::Model

  # user            : current_user（コントローラで注入）
  # roadmap_attributes : RoadmapGoal の属性ハッシュ（title/reason/start_month/target_month/category_id/status）
  # target_months   : 保存対象の月初 Date 配列（コントローラが build_target_months で生成した正データ）
  # monthly_titles  : { Date(月初) => "入力タイトル" } のハッシュ
  attr_accessor :user, :roadmap_attributes, :target_months, :monthly_titles

  # 作成した RoadmapGoal を外から参照できるようにする
  attr_reader :roadmap_goal

  def initialize(user:, roadmap_attributes:, target_months:, monthly_titles:)
    @user = user
    @roadmap_attributes = (roadmap_attributes || {}).to_h.symbolize_keys
    @target_months = target_months || []
    @monthly_titles = monthly_titles || {}
  end

  def save
    build_roadmap_goal

    # RoadmapGoal 単体の妥当性 + 全月の必須チェックをまとめて検証
    validate_roadmap_goal
    validate_monthly_titles
    return false if errors.any?

    persist!
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def build_roadmap_goal
    # user_id はクライアント入力を使わず current_user 経由で確定する
    @roadmap_goal = user.roadmap_goals.build(permitted_roadmap_attributes)
  end

  # RoadmapGoal に渡してよい属性だけに絞る（user_id 等は受け取らない）
  def permitted_roadmap_attributes
    @roadmap_attributes.slice(
      :title, :reason, :start_month, :target_month, :category_id, :status
    )
  end

  def validate_roadmap_goal
    return if @roadmap_goal.valid?

    @roadmap_goal.errors.each do |error|
      errors.add(:base, "ロードマップ目標: #{error.full_message}")
    end
  end

  # すべての対象月の入力が埋まっていることを必須チェックする
  def validate_monthly_titles
    @target_months.each do |month|
      title = monthly_title_for(month)
      next if title.present?

      errors.add(:base, "#{month.strftime('%Y年%-m月')}の目標を入力してください")
    end
  end

  def persist!
    ActiveRecord::Base.transaction do
      @roadmap_goal.save!

      @target_months.each do |month|
        build_monthly_goal(month).save!
      end
    end
  end

  def build_monthly_goal(month)
    # user / category / roadmap_goal / goal_kind / target_month は Form 側で確定する
    @roadmap_goal.monthly_goals.build(
      title: monthly_title_for(month),
      target_month: month,
      user: user,
      category_id: @roadmap_goal.category_id,
      goal_kind: :step
    )
  end

  def monthly_title_for(month)
    value = @monthly_titles[month] || @monthly_titles[month.to_s]
    value.to_s.strip
  end
end
