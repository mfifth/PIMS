class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: t('notifications.try_again_later') }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))
    msg = user&.confirmed_at ? t('notifications.try_another_login') : t('notifications.confirm_email')

    if user && user.confirmed_at.present?
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: msg
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
