class MypagesController < ApplicationController
  def show
    @today = Date.current

    weekly_goals = current_user.weekly_goals
                               .includes(
                                 :category,
                                 :daily_records,
                                 monthly_goal: [ :category, :roadmap_goal ]
                               )
                               .where(
                                 start_date: (@today - 6.days)..@today
                               )
                               .order(created_at: :desc)

    @cards = weekly_goals.map do |weekly|
      monthly = weekly.monthly_goal
      roadmap = monthly&.roadmap_goal

      today_record = weekly.daily_records.find do |dr|
        dr.record_date == @today
      end

      origin =
        if roadmap
          :roadmap
        elsif monthly
          :monthly
        else
          :weekly
        end

      {
        weekly_goal: weekly,
        monthly_goal: monthly,
        roadmap_goal: roadmap,
        today_record: today_record,
        origin: origin
      }
    end
  end
end
