FactoryBot.define do
  factory :monthly_goal do
    association :user
    association :category

    title { "テスト用月目標" }
    target_month { Date.new(2026, 7, 1) }
    goal_kind { :single }
    roadmap_goal { nil }
  end
end
