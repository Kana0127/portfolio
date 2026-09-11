class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges,
  # import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # 原則すべてのアクションでログインを必須にする
  before_action :require_login

  # 各リクエストで言語を切り替える
  around_action :switch_locale

  private

  # Sorcery が require_login で未ログインを検知したときに呼び出す
  def not_authenticated
    redirect_to login_path, alert: "ログインしてください"
  end

  def switch_locale(&action)
    locale =
      if I18n.available_locales.map(&:to_s).include?(params[:locale])
        params[:locale]
      else
        I18n.default_locale
      end

    I18n.with_locale(locale, &action)
  end
end
