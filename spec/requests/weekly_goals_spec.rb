require "rails_helper"

RSpec.describe "WeeklyGoals", type: :request do
  let(:password) { "password" }

  def login_as(target_user)
    post login_path,
         params: {
           email: target_user.email,
           password: password
         }
  end

  describe "POST /weekly_goals" do
    it "単独の週目標を作成できる" do
      user = create(
        :user,
        password: password,
        password_confirmation: password
      )
      category = create(:category)

      login_as(user)

      expect {
        post weekly_goals_path,
             params: {
               weekly_goal: {
                 title: "英語を勉強する",
                 start_date: "2026-09-20",
                 category_id: category.id
               }
             }
      }.to change(WeeklyGoal, :count).by(1)

      weekly_goal = WeeklyGoal.last

      expect(weekly_goal.user).to eq user
      expect(weekly_goal.monthly_goal).to be_nil
      expect(weekly_goal.category).to eq category
    end
  end
end