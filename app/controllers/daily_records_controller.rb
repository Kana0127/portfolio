class DailyRecordsController < ApplicationController
  before_action :set_weekly_goal
  before_action :redirect_if_today_recorded, only: %i[new]

  def new
    @daily_record = @weekly_goal.daily_records.build(record_date: Date.current)
  end

  def create
    @daily_record = @weekly_goal.daily_records.build(daily_record_params)
    @daily_record.record_date = Date.current

    if @daily_record.save
      flash[:notice] = "今日の記録を保存しました"
      redirect_to mypage_path
    else
      flash.now[:alert] = "記録を保存できませんでした"
      render :new, status: :unprocessable_entity
    end
  end

  private

  # 本人の週目標だけを取得する。
  # current_user.weekly_goals は has_many :through で
  # monthly_goals -> weekly_goals と辿るので、他人の週目標IDは届かない。
  def set_weekly_goal
    @weekly_goal = current_user.weekly_goals.find(params[:weekly_goal_id])
  end

  # 同じ週目標に今日の記録が既にあるなら一覧に戻す（MVPでは編集・削除なし）
  def redirect_if_today_recorded
    return unless @weekly_goal.daily_records.exists?(record_date: Date.current)

    redirect_to monthly_goals_path, notice: "今日の記録はすでに登録されています"
  end

  # status / memo のみ permit。record_date / weekly_goal_id は受け取らない
  def daily_record_params
    params.require(:daily_record).permit(:status, :memo)
  end
end
