require "rails_helper"

# issue37: ロードマップ目標 + 期間分の月目標を一括作成するフロー
RSpec.describe "RoadmapGoal creation flow", type: :request do
  let(:password) { "password" }
  let(:user)     { create(:user, password: password, password_confirmation: password) }
  let(:category) { create(:category) }

  def login_as(target_user)
    post login_path, params: { email: target_user.email, password: password }
  end

  # 2026年7月〜9月（3か月）のロードマップ入力値
  let(:roadmap_params) do
    {
      roadmap_goal: {
        title: "ITエンジニアに転職",
        reason: "実力をつけたい",
        start_month: "2026-07",
        target_month: "2026-09",
        category_id: category.id,
        status: "active"
      }
    }
  end

  let(:monthly_titles) do
    {
      monthly_goals: {
        "2026-07-01" => { title: "基礎学習" },
        "2026-08-01" => { title: "ポートフォリオ作成" },
        "2026-09-01" => { title: "面接対策" }
      }
    }
  end

  describe "POST /roadmap_goals/monthly_goals_setup" do
    it "有効な入力で月目標設定画面を表示し、開始月〜終了月の入力欄が並ぶ" do
      login_as(user)

      post monthly_goals_setup_roadmap_goals_path, params: roadmap_params

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ITエンジニアに転職")
      # 3か月分の入力欄
      expect(response.body).to include('name="monthly_goals[2026-07-01][title]"')
      expect(response.body).to include('name="monthly_goals[2026-08-01][title]"')
      expect(response.body).to include('name="monthly_goals[2026-09-01][title]"')
    end

    it "この段階ではRoadmapGoalを保存しない" do
      login_as(user)

      expect do
        post monthly_goals_setup_roadmap_goals_path, params: roadmap_params
      end.not_to change(RoadmapGoal, :count)
    end

    it "入力が不正なら new を422で再表示する" do
      login_as(user)

      # 期間が1か月（2〜6か月バリデーション違反）
      bad = roadmap_params.deep_merge(roadmap_goal: { target_month: "2026-08" })
      post monthly_goals_setup_roadmap_goals_path, params: bad

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "未ログインでは作成フローに入れない" do
      post monthly_goals_setup_roadmap_goals_path, params: roadmap_params

      expect(response).to redirect_to(login_path)
    end
  end

  describe "POST /roadmap_goals/complete_creation" do
    before do
      login_as(user)
      # セッションに下書きを積む
      post monthly_goals_setup_roadmap_goals_path, params: roadmap_params
    end

    it "全月入力するとRoadmapGoalが1件作成される" do
      expect do
        post complete_creation_roadmap_goals_path, params: monthly_titles
      end.to change(RoadmapGoal, :count).by(1)
    end

    it "期間分のMonthlyGoalが作成される" do
      expect do
        post complete_creation_roadmap_goals_path, params: monthly_titles
      end.to change(MonthlyGoal, :count).by(3)
    end

    it "作成後、ロードマップ詳細画面へ遷移する" do
      post complete_creation_roadmap_goals_path, params: monthly_titles

      roadmap_goal = user.roadmap_goals.last
      expect(response).to redirect_to(roadmap_goal_path(roadmap_goal))
    end

    it "MonthlyGoalに正しいtarget_month/roadmap/user/category/goal_kindが設定される" do
      post complete_creation_roadmap_goals_path, params: monthly_titles

      roadmap_goal = user.roadmap_goals.last
      monthly_goals = roadmap_goal.monthly_goals.order(:target_month)

      expect(monthly_goals.map(&:target_month)).to eq(
        [ Date.new(2026, 7, 1), Date.new(2026, 8, 1), Date.new(2026, 9, 1) ]
      )
      expect(monthly_goals.map(&:title)).to eq(%w[基礎学習 ポートフォリオ作成 面接対策])
      expect(monthly_goals).to all(have_attributes(user_id: user.id))
      expect(monthly_goals).to all(have_attributes(roadmap_goal_id: roadmap_goal.id))
      expect(monthly_goals).to all(have_attributes(category_id: roadmap_goal.category_id))
      expect(monthly_goals).to all(be_step)
    end

    it "1件でも空欄ならRoadmapGoalもMonthlyGoalも保存されない（部分保存が残らない）" do
      missing = monthly_titles.deep_merge(monthly_goals: { "2026-08-01" => { title: "" } })

      expect do
        post complete_creation_roadmap_goals_path, params: missing
      end.to change(RoadmapGoal, :count).by(0)

      expect(MonthlyGoal.count).to eq(0)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /roadmap_goals/complete_creation（セッションなし）" do
    it "セッションに下書きがない場合は新規作成画面へ戻る" do
      # setup を経由せずログインだけした状態で complete_creation を叩く
      login_as(user)

      post complete_creation_roadmap_goals_path, params: monthly_titles

      expect(response).to redirect_to(new_roadmap_goal_path)
    end
  end
end
