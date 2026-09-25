require "rails_helper"

RSpec.describe WeeklyGoal, type: :model do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  describe "月目標との関連" do
    it "月目標がなくても有効である" do
      weekly_goal = build(
        :weekly_goal,
        monthly_goal: nil,
        user: user,
        category: category,
        start_date: Date.new(2026, 9, 6)
      )

      expect(weekly_goal).to be_valid
    end

    it "月目標がある場合も有効である" do
      monthly_goal = create(
        :monthly_goal,
        target_month: Date.new(2026, 9, 1)
      )

      weekly_goal = build(
        :weekly_goal,
        monthly_goal: monthly_goal,
        user: monthly_goal.user,
        category: monthly_goal.category,
        start_date: Date.new(2026, 9, 6)
      )

      expect(weekly_goal).to be_valid
    end
  end

  describe "week_numberの自動設定" do
    it "単独週目標でもstart_dateからweek_numberを設定できる" do
      weekly_goal = build(
        :weekly_goal,
        monthly_goal: nil,
        user: user,
        category: category,
        start_date: Date.new(2026, 9, 13)
      )

      weekly_goal.valid?

      expect(weekly_goal.week_number).to eq 3
    end
  end

  describe "start_dateのバリデーション" do
    context "候補日の場合" do
      it "有効である" do
        weekly_goal = build(
          :weekly_goal,
          monthly_goal: nil,
          user: user,
          category: category,
          start_date: Date.new(2026, 9, 20)
        )

        expect(weekly_goal).to be_valid
      end
    end

    context "候補日ではない場合" do
      it "無効である" do
        weekly_goal = build(
          :weekly_goal,
          monthly_goal: nil,
          user: user,
          category: category,
          start_date: Date.new(2026, 9, 15)
        )

        expect(weekly_goal).not_to be_valid
        expect(weekly_goal.errors[:start_date]).to be_present
      end
    end
  end
end