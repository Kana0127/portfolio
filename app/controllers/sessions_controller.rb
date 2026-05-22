class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
  end

  def create
    if login(params[:email], params[:password])
      flash[:notice] = "ログインしました"
      redirect_to root_path
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    flash[:notice] = "ログアウトしました"
    redirect_to root_path
  end
end
