require "rails_helper"

RSpec.describe MonthlyGoal, type: :model do
  describe "ロードマップ目標との関連" do
    it "ロードマップ目標が未選択でも有効である" do
      monthly_goal = build(:monthly_goal, roadmap_goal: nil)

      expect(monthly_goal).to be_valid
    end

    it "同じユーザーのロードマップ目標に紐づけられる" do
      user = create(:user)
      category = create(:category)

      roadmap_goal = create(
        :roadmap_goal,
        user: user,
        category: category
      )

      monthly_goal = build(
        :monthly_goal,
        user: user,
        category: category,
        roadmap_goal: roadmap_goal
      )

      expect(monthly_goal).to be_valid
    end

    it "他ユーザーのロードマップ目標には紐づけられない" do
      user = create(:user)
      other_user = create(:user)
      category = create(:category)

      other_roadmap_goal = create(
        :roadmap_goal,
        user: other_user,
        category: category
      )

      monthly_goal = build(
        :monthly_goal,
        user: user,
        category: category,
        roadmap_goal: other_roadmap_goal
      )

      expect(monthly_goal).not_to be_valid
      expect(monthly_goal.errors[:roadmap_goal]).to be_present
    end
  end
end