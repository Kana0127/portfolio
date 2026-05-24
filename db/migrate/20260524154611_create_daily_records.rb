class CreateDailyRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_records do |t|
      t.references :weekly_goal, null: false, foreign_key: true
      t.date :record_date, null: false
      t.integer :status, null: false
      t.text :memo

      t.timestamps
    end

    # 同じ週目標に対して同じ日付の記録は1件のみ
    add_index :daily_records, [ :weekly_goal_id, :record_date ], unique: true, name: "index_daily_records_on_wg_and_record_date"
  end
end
