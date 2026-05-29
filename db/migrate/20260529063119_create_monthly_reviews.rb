class CreateMonthlyReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_reviews do |t|
      # 1つの月目標に対して月次振り返りは1件のみ
      t.references :monthly_goal, null: false, foreign_key: true, index: { unique: true }
      t.integer :achievement_rate, null: false
      t.text :good_point, null: false
      t.text :improvement_point, null: false
      t.text :memo

      t.timestamps
    end
  end
end
