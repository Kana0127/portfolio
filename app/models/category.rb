class Category < ApplicationRecord
  has_many :monthly_goals, dependent: :restrict_with_exception
  has_many :weekly_goals
  validates :name, presence: true, uniqueness: true
end
