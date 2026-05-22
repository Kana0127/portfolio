# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 月目標で使う固定カテゴリー（全ユーザー共通のマスターデータ）
# find_or_create_by! を使うことで、db:seed を複数回実行しても重複しないようにする
default_categories = [
  "趣味",
  "資格・学習",
  "遊び・旅行",
  "スポーツ",
  "美容・健康",
  "読書",
  "お金",
  "その他"
]

default_categories.each do |category_name|
  Category.find_or_create_by!(name: category_name)
end
