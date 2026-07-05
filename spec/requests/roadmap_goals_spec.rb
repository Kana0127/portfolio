require "rails_helper"

RSpec.describe "RoadmapGoals", type: :request do
  let(:password) { "password" }
  let(:user)     { create(:user, password: password, password_confirmation: password) }
  let(:category) { create(:category) }

  # Sorcery はセッションベースなので、ログインは実際に POST /login で行う
  def login_as(target_user)
    post login_path, params: { email: target_user.email, password: password }
  end

  describe "GET /roadmap_goals/new" do
    it "ログイン中はロードマップ目標の新規作成画面を表示できる" do
      login_as(user)

      get new_roadmap_goal_path

      expect(response).to have_http_status(:ok)
    end

    it "未ログインならログイン画面にリダイレクトする" do
      get new_roadmap_goal_path

      expect(response).to redirect_to(login_path)
    end
  end

  describe "POST /roadmap_goals" do
    let(:valid_params) do
      {
        roadmap_goal: {
          title: "ITエンジニアとしてのスキルアップ",
          reason: "転職に向けた実力をつけたいから",
          start_month: "2026-04",
          target_month: "2026-09",
          category_id: category.id,
          status: "active"
        }
      }
    end

    it "ログイン中ユーザーに紐づくRoadmapGoalを作成できる" do
      login_as(user)

      expect do
        post roadmap_goals_path, params: valid_params
      end.to change(user.roadmap_goals, :count).by(1)

      roadmap_goal = user.roadmap_goals.last
      expect(roadmap_goal.title).to eq("ITエンジニアとしてのスキルアップ")
      expect(roadmap_goal.start_month).to eq(Date.new(2026, 4, 1))
      expect(roadmap_goal.target_month).to eq(Date.new(2026, 9, 1))
      expect(response).to redirect_to(roadmap_goal_path(roadmap_goal))
    end

    it "作成したRoadmapGoalが目標一覧画面に表示される" do
      login_as(user)
      post roadmap_goals_path, params: valid_params

      get monthly_goals_path

      expect(response.body).to include("ITエンジニアとしてのスキルアップ")
    end

    it "期間が1か月なら作成できず新規作成画面を再表示する" do
      login_as(user)

      expect do
        post roadmap_goals_path, params: valid_params.deep_merge(
          roadmap_goal: { start_month: "2026-04", target_month: "2026-05" }
        )
      end.not_to change(RoadmapGoal, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /roadmap_goals/:id" do
    it "本人のRoadmapGoal詳細を表示できる" do
      login_as(user)
      roadmap_goal = create(:roadmap_goal, user: user, category: category)

      get roadmap_goal_path(roadmap_goal)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(roadmap_goal.title)
    end

    it "他ユーザーのRoadmapGoal詳細にはアクセスできない" do
      other_user = create(:user, password: password, password_confirmation: password)
      others_goal = create(:roadmap_goal, user: other_user)

      login_as(user)
      get roadmap_goal_path(others_goal)

      # current_user.roadmap_goals.find は RecordNotFound → Rails が 404 を返す
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /roadmap_goals/:id/edit" do
    it "自分のRoadmapGoal編集画面を表示できる" do
      login_as(user)
      roadmap_goal = create(:roadmap_goal, user: user, category: category)

      get edit_roadmap_goal_path(roadmap_goal)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(roadmap_goal.title)
    end

    it "他ユーザーのRoadmapGoal編集画面にはアクセスできない" do
      others_goal = create(:roadmap_goal, user: create(:user))

      login_as(user)
      get edit_roadmap_goal_path(others_goal)

      # current_user.roadmap_goals.find が RecordNotFound → 404
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /roadmap_goals/:id" do
    it "自分のRoadmapGoalを更新でき、内容が反映される" do
      login_as(user)
      roadmap_goal = create(:roadmap_goal, user: user, category: category, title: "更新前タイトル")

      patch roadmap_goal_path(roadmap_goal), params: {
        roadmap_goal: { title: "更新後タイトル" }
      }

      expect(response).to redirect_to(roadmap_goal_path(roadmap_goal))
      expect(roadmap_goal.reload.title).to eq("更新後タイトル")

      follow_redirect!
      expect(response.body).to include("更新後タイトル")
    end

    it "他ユーザーのRoadmapGoalは更新できない" do
      others_goal = create(:roadmap_goal, user: create(:user), title: "他人の目標")

      login_as(user)
      patch roadmap_goal_path(others_goal), params: {
        roadmap_goal: { title: "書き換え" }
      }

      expect(response).to have_http_status(:not_found)
      expect(others_goal.reload.title).to eq("他人の目標")
    end
  end

  describe "DELETE /roadmap_goals/:id" do
    it "自分のRoadmapGoalを削除でき、件数が減る" do
      login_as(user)
      roadmap_goal = create(:roadmap_goal, user: user, category: category)

      expect do
        delete roadmap_goal_path(roadmap_goal)
      end.to change(user.roadmap_goals, :count).by(-1)

      expect(response).to redirect_to(monthly_goals_path)
    end

    it "他ユーザーのRoadmapGoalは削除できない" do
      others_goal = create(:roadmap_goal, user: create(:user))

      login_as(user)

      expect do
        delete roadmap_goal_path(others_goal)
      end.not_to change(RoadmapGoal, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
