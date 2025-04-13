class SessionsController < ApplicationController

  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))
    msg = user.confirmed_at ? "Try another email address or password." : "Please confirm your email before logging in."

    if user && user.confirmed_at
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
