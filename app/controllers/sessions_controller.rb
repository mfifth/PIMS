class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: t('notifications.try_again_later') }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))
    
    if user&.confirmed_at.present?
      reset_session
      start_new_session_for(user)
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, 
        alert: user ? t('notifications.confirm_email') : t('notifications.try_another_login')
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
