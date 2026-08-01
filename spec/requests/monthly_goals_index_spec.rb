require "rails_helper"

RSpec.describe "MonthlyGoals index", type: :request do
  let(:password) { "password" }
  let(:user)     { create(:user, password: password, password_confirmation: password) }
  let(:category) { create(:category) }

  # 月をまたいだ判定を安定させるため、月中の日付に固定する
  let(:today)         { Date.new(2026, 7, 15) }
  let(:current_month) { today.beginning_of_month }

  def login_as(target_user)
    post login_path, params: { email: target_user.email, password: password }
  end

  before do
    travel_to(today)
    login_as(user)
  end

  after { travel_back }

  describe "ロードマップ目標の表示" do
    it "進行中かつ今月が期間内のロードマップが表示される" do
      create(:roadmap_goal,
             user: user, category: category,
             title: "ITエンジニアに転職",
             start_month: Date.new(2026, 6, 1),
             target_month: Date.new(2026, 9, 1),
             status: :active)

      get monthly_goals_path

      expect(response.body).to include("ITエンジニアに転職")
    end

    it "進行中でないロードマップは表示されない" do
      create(:roadmap_goal,
             user: user, category: category,
             title: "一時停止したロードマップ",
             start_month: Date.new(2026, 6, 1),
             target_month: Date.new(2026, 9, 1),
             status: :paused)

      get monthly_goals_path

      expect(response.body).not_to include("一時停止したロードマップ")
    end

    it "終了月が過ぎたロードマップは表示されない" do
      create(:roadmap_goal,
             user: user, category: category,
             title: "終了済みロードマップ",
             start_month: Date.new(2026, 1, 1),
             target_month: Date.new(2026, 4, 1),
             status: :active)

      get monthly_goals_path

      expect(response.body).not_to include("終了済みロードマップ")
    end

    it "開始月がまだ先のロードマップは表示されない" do
      create(:roadmap_goal,
             user: user, category: category,
             title: "未来のロードマップ",
             start_month: Date.new(2026, 9, 1),
             target_month: Date.new(2026, 12, 1),
             status: :active)

      get monthly_goals_path

      expect(response.body).not_to include("未来のロードマップ")
    end

    it "他ユーザーのロードマップは表示されない" do
      other_user = create(:user)
      create(:roadmap_goal,
             user: other_user, category: category,
             title: "他人のロードマップ",
             start_month: Date.new(2026, 6, 1),
             target_month: Date.new(2026, 9, 1),
             status: :active)

      get monthly_goals_path

      expect(response.body).not_to include("他人のロードマップ")
    end

    it "残り期間が表示される" do
      create(:roadmap_goal,
             user: user, category: category,
             start_month: Date.new(2026, 6, 1),
             target_month: Date.new(2026, 9, 1),
             status: :active)

      get monthly_goals_path

      expect(response.body).to include("残り2か月")
    end
  end

  describe "ロードマップに紐づく月目標の表示" do
    let(:roadmap) do
      create(:roadmap_goal,
             user: user, category: category,
             start_month: Date.new(2026, 6, 1),
             target_month: Date.new(2026, 9, 1),
             status: :active)
    end

    it "紐づく今月の月目標が表示される" do
      create(:monthly_goal,
             user: user, category: category, roadmap_goal: roadmap,
             title: "TOEIC 850点を取る",
             target_month: current_month)

      get monthly_goals_path

      expect(response.body).to include("TOEIC 850点を取る")
    end

    it "紐づく別月の月目標は今月の目標として表示されない" do
      create(:monthly_goal,
             user: user, category: category, roadmap_goal: roadmap,
             title: "先月のロードマップ月目標",
             target_month: current_month.prev_month)

      get monthly_goals_path

      expect(response.body).not_to include("先月のロードマップ月目標")
    end

    it "月目標に紐づく週目標が表示される" do
      monthly_goal = create(:monthly_goal,
                            user: user, category: category, roadmap_goal: roadmap,
                            title: "TOEIC 850点を取る",
                            target_month: current_month)
      create(:weekly_goal, monthly_goal: monthly_goal, title: "公式問題集を1周する")

      get monthly_goals_path

      expect(response.body).to include("公式問題集を1周する")
    end
  end

  describe "ロードマップに紐づかない月目標の表示" do
    it "ロードマップなしの月目標も表示される" do
      create(:monthly_goal,
             user: user, category: category, roadmap_goal: nil,
             title: "体重2kg減",
             target_month: current_month)

      get monthly_goals_path

      expect(response.body).to include("体重2kg減")
      expect(response.body).to include("月目標（ロードマップなし）")
    end

    it "ロードマップなし月目標に紐づく週目標も表示される" do
      monthly_goal = create(:monthly_goal,
                            user: user, category: category, roadmap_goal: nil,
                            target_month: current_month)
      create(:weekly_goal, monthly_goal: monthly_goal, title: "食事記録をつける")

      get monthly_goals_path

      expect(response.body).to include("食事記録をつける")
    end

    it "他ユーザーの月目標は表示されない" do
      other_user = create(:user)
      create(:monthly_goal,
             user: other_user, category: category,
             title: "他人の月目標",
             target_month: current_month)

      get monthly_goals_path

      expect(response.body).not_to include("他人の月目標")
    end
  end
end
