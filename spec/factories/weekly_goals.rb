FactoryBot.define do
  factory :weekly_goal do
    association :monthly_goal

    title { "テスト用週目標" }
    # start_date は対象月の1日または対象月内の日曜日である必要がある
    start_date { monthly_goal.target_month.beginning_of_month }
  end
end
