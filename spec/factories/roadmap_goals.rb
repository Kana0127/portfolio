FactoryBot.define do
  factory :roadmap_goal do
    association :user
    association :category

    title { "3か月でMonthly Stepを本リリースする" }
    reason { "ポートフォリオの完成度を高めたいから" }
    start_month { Date.new(2026, 7, 1) }
    target_month { Date.new(2026, 9, 1) }
    status { :active }
  end
end
