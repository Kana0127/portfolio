FactoryBot.define do
  factory :weekly_goal do
    association :monthly_goal

    user { monthly_goal.user }
    category { monthly_goal.category }

    title { "テスト用週目標" }

    start_date do
      monthly_goal.target_month.beginning_of_month
    end

    trait :standalone do
      monthly_goal { nil }

      association :user
      association :category

      start_date { Date.current.beginning_of_month }
    end
  end
end
