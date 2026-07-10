require "rails_helper"

RSpec.describe RoadmapGoal, type: :model do
  describe "validations" do
    it "有効な情報があれば保存できる" do
      roadmap_goal = build(:roadmap_goal)

      expect(roadmap_goal).to be_valid
    end

    it "titleが空なら保存できない" do
      roadmap_goal = build(:roadmap_goal, title: "")

      expect(roadmap_goal).not_to be_valid
      expect(roadmap_goal.errors[:title]).to be_present
    end

    it "start_monthが空なら保存できない" do
      roadmap_goal = build(:roadmap_goal, start_month: nil)

      expect(roadmap_goal).not_to be_valid
      expect(roadmap_goal.errors[:start_month]).to be_present
    end

    it "target_monthが空なら保存できない" do
      roadmap_goal = build(:roadmap_goal, target_month: nil)

      expect(roadmap_goal).not_to be_valid
      expect(roadmap_goal.errors[:target_month]).to be_present
    end

    it "target_monthがstart_monthより前なら保存できない" do
      roadmap_goal = build(
        :roadmap_goal,
        start_month: Date.new(2026, 9, 1),
        target_month: Date.new(2026, 7, 1)
      )

      expect(roadmap_goal).not_to be_valid
      expect(roadmap_goal.errors[:target_month]).to be_present
    end
  end

  describe "期間バリデーション（2〜6か月）" do
    it "1か月以内のロードマップゴールは無効" do
      roadmap_goal = build(
        :roadmap_goal,
        start_month: Date.new(2026, 7, 1),
        target_month: Date.new(2026, 8, 1)
      )

      expect(roadmap_goal).not_to be_valid
      expect(roadmap_goal.errors[:target_month]).to be_present
    end

    it "2か月のロードマップゴールは有効" do
      roadmap_goal = build(
        :roadmap_goal,
        start_month: Date.new(2026, 7, 1),
        target_month: Date.new(2026, 9, 1)
      )

      expect(roadmap_goal).to be_valid
    end

    it "6か月のロードマップゴールは有効" do
      roadmap_goal = build(
        :roadmap_goal,
        start_month: Date.new(2026, 7, 1),
        target_month: Date.new(2027, 1, 1)
      )

      expect(roadmap_goal).to be_valid
    end

    it "7か月以上のロードマップゴールは無効" do
      roadmap_goal = build(
        :roadmap_goal,
        start_month: Date.new(2026, 7, 1),
        target_month: Date.new(2027, 2, 1)
      )

      expect(roadmap_goal).not_to be_valid
      expect(roadmap_goal.errors[:target_month]).to be_present
    end
  end

  describe "status" do
    it "初期値がactiveになる" do
      roadmap_goal = RoadmapGoal.new

      expect(roadmap_goal.status).to eq("active")
      expect(roadmap_goal).to be_active
    end

    it "statusをenumで管理できる" do
      roadmap_goal = create(:roadmap_goal)

      expect(roadmap_goal).to be_active

      roadmap_goal.achieved!

      expect(roadmap_goal).to be_achieved
    end
  end

  describe "月目標との関連" do
    it "ロードマップ目標を削除すると紐づく月目標も削除される" do
      user = create(:user)
      category = create(:category)

      roadmap_goal = create(
        :roadmap_goal,
        user: user,
        category: category
      )

      create(
        :monthly_goal,
        user: user,
        category: category,
        roadmap_goal: roadmap_goal
      )

      expect {
        roadmap_goal.destroy
      }.to change(MonthlyGoal, :count).by(-1)
    end

    it "ロードマップに紐づかない月目標は削除されない" do
      user = create(:user)
      category = create(:category)

      roadmap_goal = create(
        :roadmap_goal,
        user: user,
        category: category
      )

      standalone_monthly_goal = create(
        :monthly_goal,
        user: user,
        category: category,
        roadmap_goal: nil
      )

      roadmap_goal.destroy

      expect(
        MonthlyGoal.exists?(standalone_monthly_goal.id)
      ).to be true
    end
  end
end
