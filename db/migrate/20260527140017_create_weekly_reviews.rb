class CreateWeeklyReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_reviews do |t|
      # index: { unique: true } で 1つのユニークインデックスにまとめる
      t.references :weekly_goal, null: false, foreign_key: true, index: { unique: true }
      t.integer :achievement_rate, null: false
      t.text :good_point, null: false
      t.text :improvement_point, null: false
      t.text :memo

      t.timestamps
    end
  end
end
