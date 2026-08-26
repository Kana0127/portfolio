# WeeklyGoalモデル
# ApplicationRecordを継承しているため、
# weekly_goalsテーブルのデータをRubyのオブジェクトとして扱える
class WeeklyGoal < ApplicationRecord

  # ============================================================
  # 定数
  # ============================================================

  # Monthly Stepでは、1か月を最大5週として扱う。
  #
  # week_numberには
  # 1, 2, 3, 4, 5
  # のいずれかが入る。
  #
  # 「5」という数字をコード中に直接何度も書かず、
  # MAX_WEEKSという名前を付けて管理している。
  MAX_WEEKS = 5


  # ============================================================
  # Association（他モデルとの関連）
  # ============================================================

  # WeeklyGoalはMonthlyGoalに属することができる。
  #
  # optional: true があるため、
  # monthly_goal_id がnilでもRailsのバリデーション上は許可される。
  #
  # つまり、
  #
  # 月目標あり
  #   MonthlyGoal
  #       ↓
  #   WeeklyGoal
  #
  # だけでなく、
  #
  # 月目標なし
  #   WeeklyGoal単独
  #
  # でも作成できる設計。
  belongs_to :monthly_goal, optional: true


  # WeeklyGoalは必ず1人のUserに属する。
  #
  # optional: true を付けていないため、
  # 原則としてuserが存在しないWeeklyGoalは保存できない。
  belongs_to :user


  # WeeklyGoalは必ず1つのCategoryに属する。
  belongs_to :category


  # 1つのWeeklyGoalには複数のDailyRecordを持つことができる。
  #
  # dependent: :destroy により、
  # WeeklyGoalを削除した場合、
  # それに紐づくDailyRecordも一緒に削除される。
  has_many :daily_records, dependent: :destroy


  # 1つのWeeklyGoalにつきWeeklyReviewは1つ。
  #
  # WeeklyGoalが削除された場合、
  # 紐づくWeeklyReviewも削除する。
  has_one :weekly_review, dependent: :destroy


  # ============================================================
  # Callback
  # ============================================================

  # バリデーションが実行される「前」に
  # assign_week_numberメソッドを実行する。
  #
  # start_dateをもとに、
  # 「第何週なのか」を自動的にweek_numberへ入れるため。
  #
  # 例：
  # start_date = 2026/8/16
  # ↓
  # 第4週
  # ↓
  # week_number = 4
  before_validation :assign_week_number


  # ============================================================
  # Validation
  # ============================================================

  # titleは必須。
  #
  # titleがnilまたは空文字の場合、
  # WeeklyGoalは保存できない。
  validates :title, presence: true


  # week_numberは必須。
  #
  # また、
  # 1〜MAX_WEEKS（現在は5）
  # の範囲内でなければならない。
  #
  # つまり、
  # 0
  # 6
  # nil
  # などは保存できない。
  validates :week_number,
            presence: true,
            inclusion: { in: 1..MAX_WEEKS }


  # その週がいつ始まるのかを表すstart_dateは必須。
  validates :start_date, presence: true


  # Rails標準のバリデーションではなく、
  # 自分で作成したカスタムバリデーション。
  #
  # start_dateが
  # 「Monthly Stepで許可している週の開始日」
  # になっているか確認する。
  validate :start_date_must_be_valid_candidate


  # ============================================================
  # start_date候補を作るクラスメソッド
  # ============================================================

  # 指定された月について、
  # WeeklyGoalのstart_dateとして選択できる日付一覧を返す。
  #
  # Monthly Stepでは、
  #
  # ・月初（1日）
  # ・その月の日曜日
  #
  # を週の開始候補としている。
  #
  # ただし最大5週まで。
  #
  #
  # 例：
  #
  # 2026年5月
  #
  # 5/1 金
  # 5/3 日
  # 5/10 日
  # 5/17 日
  # 5/24 日
  # 5/31 日
  #
  # ↓ 最大5個に制限
  #
  # [
  #   5/1,
  #   5/3,
  #   5/10,
  #   5/17,
  #   5/24
  # ]
  #
  #
  # self. が付いているため、
  # WeeklyGoal.start_date_candidates(...)
  #
  # のようにWeeklyGoalクラスそのものから呼び出す。
  def self.start_date_candidates(target_month)

    # target_monthがnilや空の場合、
    # 日付候補を計算できないので空配列[]を返して終了する。
    #
    # returnによって、
    # この下の処理は実行されない。
    return [] if target_month.blank?


    # target_monthが属する月の1日を取得。
    #
    # 例：
    # target_month = 2026/8/18
    #
    # ↓
    #
    # first_day = 2026/8/1
    first_day = target_month.beginning_of_month


    # target_monthが属する月の最終日を取得。
    #
    # 例：
    # target_month = 2026/8/18
    #
    # ↓
    #
    # last_day = 2026/8/31
    last_day = target_month.end_of_month


    # first_day..last_day
    #
    # で、その月の1日〜最終日までの日付範囲を作る。
    #
    # 例：
    #
    # 8/1
    # 8/2
    # 8/3
    # ...
    # 8/31
    #
    # select(&:sunday?)
    #
    # により、その中から
    # 「日曜日だけ」を取り出す。
    #
    # 例：
    #
    # [
    #   8/2,
    #   8/9,
    #   8/16,
    #   8/23,
    #   8/30
    # ]
    sundays = (first_day..last_day).select(&:sunday?)


    # 月初の1日が日曜日かどうかを確認する。
    if first_day.sunday?

      # もし1日自体が日曜日なら、
      #
      # sundaysの中にすでに1日が入っている。
      #
      # そのため、
      # 「1日 + 日曜日」
      # とすると1日が重複してしまう。
      #
      # なので日曜日一覧をそのまま使う。
      #
      # first(MAX_WEEKS)
      # により最大5個まで取得する。
      sundays.first(MAX_WEEKS)

    else

      # 1日が日曜日ではない場合、
      #
      # [first_day]
      #
      # で「月初1日だけの配列」を作る。
      #
      # そこに
      #
      # + sundays
      #
      # で日曜日一覧を追加する。
      #
      # 例：
      #
      # [8/1]
      #
      # +
      #
      # [8/2, 8/9, 8/16, 8/23, 8/30]
      #
      # ↓
      #
      # [8/1, 8/2, 8/9, 8/16, 8/23, 8/30]
      #
      # さらにfirst(MAX_WEEKS)で、
      # 最初の5個だけを取得する。
      #
      # ↓
      #
      # [8/1, 8/2, 8/9, 8/16, 8/23]
      ([first_day] + sundays).first(MAX_WEEKS)
    end
  end


  # ============================================================
  # start_dateからweek_numberを計算する
  # ============================================================

  # start_dateが、
  # start_date_candidatesの何番目に存在するのかを調べ、
  # 第何週かを返す。
  #
  # 例：
  #
  # candidates =
  #
  # [
  #   8/1,
  #   8/2,
  #   8/9,
  #   8/16,
  #   8/23
  # ]
  #
  # start_date = 8/16
  #
  # Rubyのindexは0から始まるため、
  #
  # 8/16 → index 3
  #
  # となる。
  #
  # しかし人間が見る「第何週」は1から始めたいので、
  #
  # 3 + 1 = 4
  #
  # として第4週を返す。
  def self.calc_week_number(start_date, target_month)

    # start_date_candidates(target_month)
    #
    # で対象月の日付候補一覧を取得する。
    #
    # .index(start_date)
    #
    # によって、
    # start_dateが配列の何番目にあるか探す。
    #
    # 見つからない場合はnil。
    idx = start_date_candidates(target_month).index(start_date)


    # Rubyの三項演算子。
    #
    # idxが存在する場合
    #   → idx + 1
    #
    # idxがnilの場合
    #   → nil
    #
    # という意味。
    #
    # 通常のif文で書くと：
    #
    # if idx
    #   idx + 1
    # else
    #   nil
    # end
    idx ? idx + 1 : nil
  end


  # ============================================================
  # 「今日」が対象月の何週目なのか計算する
  # ============================================================

  # todayの日付をもとに、
  # 現在がMonthly Step上の第何週なのかを返す。
  #
  # start_dateと完全一致する必要はなく、
  #
  # 「today以下で最も新しいstart_date候補」
  #
  # を探す。
  #
  # 例：
  #
  # 候補
  #
  # [
  #   5/1,
  #   5/3,
  #   5/10,
  #   5/17,
  #   5/24
  # ]
  #
  # today = 5/22
  #
  # 5/22以前で最も新しい候補は
  #
  # 5/17
  #
  # → 第4週
  def self.current_week_number(today, target_month)

    # 対象月が存在しなければ計算できないのでnilを返す。
    return nil if target_month.blank?


    # todayが対象月の範囲内にあるか確認する。
    #
    # between?(開始日, 終了日)
    #
    # なので、
    #
    # target_month.beginning_of_month
    #
    # 〜
    #
    # target_month.end_of_month
    #
    # の間にtodayがあるかを確認する。
    #
    # 対象月以外の日ならnilを返す。
    return nil unless today.between?(
      target_month.beginning_of_month,
      target_month.end_of_month
    )


    # start_date_candidatesで
    # 対象月の週開始候補を取得する。
    #
    # rindexは
    # 「条件に一致する最後の要素のindex」
    # を取得する。
    #
    # { |d| d <= today }
    #
    # は、
    #
    # 「today以前の日付」
    #
    # という条件。
    #
    # つまり、
    #
    # 今日以前の候補日の中で
    # 一番後ろにあるもの
    #
    # を探している。
    idx = start_date_candidates(target_month)
            .rindex { |d| d <= today }


    # indexは0始まりなので+1して、
    # 人間向けの「第○週」に変換する。
    #
    # 見つからなければnil。
    idx ? idx + 1 : nil
  end


  # ============================================================
  # ここから下はprivateメソッド
  # ============================================================

  # private以下のメソッドは、
  #
  # weekly_goal.assign_week_number
  #
  # のように外部から直接呼び出すことを想定していない。
  #
  # WeeklyGoalモデル内部で使用する処理として扱う。
  private


  # ============================================================
  # week_numberを自動設定する
  # ============================================================

  # before_validationから呼ばれるメソッド。
  #
  # start_dateを使って、
  # このWeeklyGoalが第何週なのかを計算し、
  # week_numberに代入する。
  def assign_week_number

    # start_dateがない場合、
    # 週番号を計算できないためここで終了。
    #
    # start_dateが空であること自体は
    # validates :start_date, presence: true
    #
    # が後ほどエラーとして処理してくれる。
    return if start_date.blank?


    # week_numberを計算するために、
    # 「どの月を基準にするのか」を決定する。
    target_month =

      # monthly_goalが存在する場合。
      if monthly_goal.present?

        # 月目標に設定されているtarget_monthを基準にする。
        #
        # 例：
        #
        # monthly_goal.target_month
        # => 2026/8/1
        monthly_goal.target_month

      else

        # monthly_goalが存在しない、
        # つまり「月目標に紐づかない単独週目標」の場合。
        #
        # start_dateが所属する月の1日を
        # target_monthとして扱う。
        #
        # 例：
        #
        # start_date
        # => 2026/8/16
        #
        # start_date.beginning_of_month
        # => 2026/8/1
        start_date.beginning_of_month
      end


    # calc_week_numberを使って、
    # start_dateが対象月の第何週なのかを計算する。
    #
    # self.week_number =
    #
    # とすることで、
    # 「現在処理しているWeeklyGoal自身」の
    # week_number属性へ値を代入している。
    #
    # 例：
    #
    # start_date = 8/16
    # target_month = 8/1
    #
    # ↓
    #
    # calc_week_number(...)
    #
    # ↓
    #
    # 4
    #
    # ↓
    #
    # self.week_number = 4
    self.week_number =
      self.class.calc_week_number(
        start_date,
        target_month
      )
  end


  # ============================================================
  # start_dateが正しい候補日なのか確認する
  # ============================================================

  # validate :start_date_must_be_valid_candidate
  #
  # から呼ばれるカスタムバリデーション。
  #
  # start_dateが
  #
  # ・月初1日
  # ・対象月の日曜日
  #
  # のいずれかであることを確認する。
  def start_date_must_be_valid_candidate

    # start_dateが空の場合、
    # ここではチェックしない。
    #
    # start_dateが必須であることについては、
    #
    # validates :start_date, presence: true
    #
    # が別にチェックするため。
    return if start_date.blank?


    # どの月を基準として
    # start_dateをチェックするのか決める。
    target_month =

      # MonthlyGoalに紐づいている場合。
      if monthly_goal.present?

        # MonthlyGoalの対象月を使用する。
        monthly_goal.target_month

      else

        # MonthlyGoalに紐づいていない場合。
        #
        # start_date自身が属する月を
        # 対象月として扱う。
        start_date.beginning_of_month
      end


    # 対象月で選択可能なstart_date一覧を取得する。
    #
    # 例：
    #
    # [
    #   8/1,
    #   8/2,
    #   8/9,
    #   8/16,
    #   8/23
    # ]
    candidates =
      self.class.start_date_candidates(target_month)


    # start_dateが候補一覧の中に存在するなら、
    # 問題ないのでここでメソッドを終了する。
    #
    # include?は
    #
    # 「その値が配列に含まれているか？」
    #
    # をtrue/falseで返す。
    return if candidates.include?(start_date)


    # start_dateが候補一覧に存在しなかった場合は、
    # バリデーションエラーを追加する。
    #
    # errors.add(:start_date, ...)
    #
    # によって、
    # start_date属性に対するエラーとして登録される。
    #
    # その結果、
    # weekly_goal.save
    #
    # はfalseになり、保存されない。
    errors.add(
      :start_date,
      "は対象月の1日または対象月内の日曜日（最大5週）から選んでください"
    )
  end
end