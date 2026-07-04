class CreateRoadmapGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :roadmap_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :title
      t.text :reason
      t.date :start_month
      t.date :target_month
      t.integer :status

      t.timestamps
    end
  end
end
