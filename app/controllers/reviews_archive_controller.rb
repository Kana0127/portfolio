class ReviewsArchiveController < ApplicationController
  # 本人の月次・週次振り返りをまとめて月ごとに表示するアーカイブページ（issue30）
  # 同じ月の月次レビューは1つの「○月 月次振り返り」カードに、
  # 同じ月・同じ週の週次レビューは1つの「○月 第○週」カードにまとめる
  def index
    weekly_reviews = WeeklyReview
                     .joins(weekly_goal: :monthly_goal)
                     .where(monthly_goals: { user_id: current_user.id })
                     .includes(weekly_goal: :monthly_goal)
                     .to_a

    monthly_reviews = MonthlyReview
                      .joins(:monthly_goal)
                      .where(monthly_goals: { user_id: current_user.id })
                      .includes(:monthly_goal)
                      .to_a

    # この画面に登場する月をすべて集めて降順に並べる
    months_in_play = (monthly_reviews.map { |r| r.monthly_goal.target_month } +
                      weekly_reviews.map { |r| r.weekly_goal.monthly_goal.target_month })
                     .uniq.sort.reverse

    @month_groups = months_in_play.map do |month|
      # その月の月次レビュー：作成順（古い→新しい）で並べる
      monthly_in_month = monthly_reviews
                         .select { |r| r.monthly_goal.target_month == month }
                         .sort_by { |r| r.monthly_goal.id }

      # その月の週次レビューを「週」ごとにまとめる
      weeklies_in_month = weekly_reviews
                          .select { |r| r.weekly_goal.monthly_goal.target_month == month }

      weekly_groups = weeklies_in_month
                      .group_by { |r| r.weekly_goal.week_number }
                      .sort_by { |week_number, _| -week_number } # 新しい週が上
                      .map do |week_number, reviews_in_week|
        sorted = reviews_in_week.sort_by { |r| r.weekly_goal.monthly_goal_id }
        {
          week_number: week_number,
          start_date:  sorted.first.weekly_goal.start_date,
          reviews:     sorted
        }
      end

      {
        target_month:    month,
        monthly_reviews: monthly_in_month,
        weekly_groups:   weekly_groups
      }
    end

    @total_count = monthly_reviews.size + weekly_reviews.size
  end
end
