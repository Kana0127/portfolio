class MypagesController < ApplicationController
  def show
    @today = Date.current
    current_month_start = @today.beginning_of_month

    # 今月の月目標すべて（複数あり得る）。
    # weekly_goals と daily_records を eager load しておき N+1 を避ける。
    monthly_goals = current_user.monthly_goals
                                .includes(:category, weekly_goals: :daily_records)
                                .where(target_month: current_month_start)
                                .order(created_at: :desc)

    # それぞれの月目標に対して、今週の週目標と今日の日次記録をまとめてビューに渡す。
    # weekly_goals は読み込み済みなので Ruby 側で .find を使い、追加クエリを発生させない。
    @cards = monthly_goals.map do |mg|
      weekly = mg.weekly_goals.find do |w|
        w.start_date <= @today && @today <= (w.start_date + 6.days)
      end
      today_record = weekly && weekly.daily_records.find { |dr| dr.record_date == @today }

      { monthly_goal: mg, weekly_goal: weekly, today_record: today_record }
    end
  end
end
