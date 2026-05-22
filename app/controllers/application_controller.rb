class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # 原則すべてのアクションでログインを必須にする
  # 未ログインで表示できる画面（TOP / 新規登録 / ログイン）は各コントローラ側で skip する
  before_action :require_login

  private

  # Sorcery が require_login で未ログインを検知したときに呼び出すコールバック
  def not_authenticated
    redirect_to login_path, alert: "ログインしてください"
  end
end
