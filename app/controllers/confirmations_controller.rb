# app/controllers/confirmations_controller.rb
class ConfirmationsController < ApplicationController
  skip_before_action :require_authentication # Allow unauthenticated access
  
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