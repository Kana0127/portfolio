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
      if valid_locale?(params[:locale])
        params[:locale]
      elsif valid_locale?(session[:locale])
        session[:locale]
      else
        browser_locale || I18n.default_locale
      end

    session[:locale] = locale

    I18n.with_locale(locale, &action)
  end

  def valid_locale?(locale)
    I18n.available_locales.map(&:to_s).include?(locale.to_s)
  end

  def browser_locale
    language =
      request.env["HTTP_ACCEPT_LANGUAGE"]
             &.scan(/^[a-z]{2}/)
             &.first

    language if valid_locale?(language)
  end
end