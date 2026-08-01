require "rails_helper"

RSpec.describe MonthlyGoalsHelper, type: :helper do
  describe "#roadmap_remaining_label" do
    let(:today) { Date.new(2026, 7, 15) }

    def roadmap_with(target_month)
      build_stubbed(:roadmap_goal, target_month: target_month)
    end

    it "終了月が先なら残り月数を返す" do
      label = helper.roadmap_remaining_label(roadmap_with(Date.new(2026, 1, 1) >> 12), today: today)
      expect(label).to eq("残り6か月")
    end

    it "終了月が今月なら「今月まで」を返す" do
      label = helper.roadmap_remaining_label(roadmap_with(Date.new(2026, 7, 1)), today: today)
      expect(label).to eq("今月まで")
    end

    it "終了月が過去なら「期間終了」を返す" do
      label = helper.roadmap_remaining_label(roadmap_with(Date.new(2026, 5, 1)), today: today)
      expect(label).to eq("期間終了")
    end

    it "月内のどの日でも月単位で判定する" do
      label = helper.roadmap_remaining_label(roadmap_with(Date.new(2026, 7, 1)), today: Date.new(2026, 7, 31))
      expect(label).to eq("今月まで")
    end

    it "target_month が未設定なら nil を返す" do
      expect(helper.roadmap_remaining_label(roadmap_with(nil), today: today)).to be_nil
    end
  end
end
