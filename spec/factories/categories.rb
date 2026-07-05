FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "学習#{n}" }
  end
end
