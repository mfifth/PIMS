# app/controllers/confirmations_controller.rb
class ConfirmationsController < ApplicationController
  skip_before_action :require_authentication # Allow unauthenticated access
  
  def show
    @user = User.find_by(confirmation_token: params[:token])
    
    if @user.nil?
      redirect_to root_path, alert: "Invalid confirmation token."
    elsif @user.confirmation_token_expired?
      redirect_to root_path, alert: "Confirmation token has expired."
    else
      @user.confirm!
      sign_in(@user) # Optional: automatically sign in after confirmation
      redirect_to dashboard_path, notice: "Your email has been confirmed successfully!"
    end
  end
end