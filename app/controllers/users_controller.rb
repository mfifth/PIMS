# app/controllers/users_controller.rb
class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  # Show the sign-up form
  def new
    @user = User.new
  end

  def show
  end

  # Create a new user account
  def create
    @user = User.new(user_params)

    if @user.save
      flash[:notice] = "Your account has been created successfully!"
      start_new_session_for @user
      redirect_to '/dashboard' # Redirect to login or dashboard after successful sign-up
    else
      render :new # Render sign-up form again with error messages
    end
  end

  def settings
  end

  def update
    if Current.user.update!(user_params)
      respond_to do |format|
        format.html { redirect_back fallback_location: '/', notice: 'Settings updated successfully.' }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :settings, status: :unprocessable_entity }
        format.turbo_stream
      end
    end
  end

  private

  # Strong parameters to permit user inputs
  def user_params
    params.require(:user).permit(:name, :email_address, :phone, :password, :password_confirmation, :email_notification, :text_notification)
  end
end
