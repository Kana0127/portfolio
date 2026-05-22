class Category < ApplicationRecord
  has_many :monthly_goals, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
end
