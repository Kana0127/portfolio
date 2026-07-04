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

  describe "enum" do
    it "statusをenumで管理できる" do
      roadmap_goal = create(:roadmap_goal)

      expect(roadmap_goal).to be_active

      roadmap_goal.achieved!

      expect(roadmap_goal).to be_achieved
    end
  end
end