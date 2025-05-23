class ConfirmationsController < ApplicationController
  skip_before_action :require_authentication # Allow unauthenticated access

  def new
  end

  def create
    user = User.find_by(email_address: params[:email].downcase.strip)

    if user && !user.confirmed?
      user.send_confirmation_email!
      redirect_to root_path, notice: t('sign_in.confirmation_sent')
    else
      flash.now[:alert] = t('sign_in.not_found_or_confirmed')
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @user = User.find_by(confirmation_token: params[:token])
    
    if @user.nil?
      redirect_to root_path, alert: t('notifications.invalid_token')
    elsif !@user.confirmation_token_valid?
      redirect_to root_path, alert: t('notifications.confirmation_token_expired')
    else
      @user.confirm!
      start_new_session_for(@user)
      redirect_to dashboard_path, notice: t('notifications.successful_email_confirm')
    end
  end
end