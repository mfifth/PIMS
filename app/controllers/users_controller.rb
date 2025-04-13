# app/controllers/users_controller.rb
class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :check_limit, only: %i[create]

  def new
    @user = User.new

    if params[:token].present?
      invitation = Invitation.find_by(token: params[:token])
      @user.email_address = invitation&.email
    end
  end

  def show
  end

  # Create a new user account
  def create
    @user = User.new(user_params)
    
    if params[:user][:invitation_token].present?
      invitation = Invitation.find_by(token: params[:user][:invitation_token])
      
      if invitation && invitation.email == @user.email_address && invitation.confirmed?
        @user.skip_account_creation = true
        account = invitation.account
      else
        flash[:alert] = "Invalid, expired, or unconfirmed invitation."
        render :new
        return
      end
    end
    
    if @user.save
      if invitation
        account.users << @user
        @user.update(role: invitation.role)
        invitation.update(accepted: true)
        start_new_session_for(@user)
        redirect_to dashboard_path, notice: "Account created successfully!"
      else
        # Normal sign up flow
        account = Account.create
        account.users << @user
        Subscription.create(account: account)
        @user.send_confirmation_email!
        redirect_to root_path, notice: "Please check your email to confirm your account"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def settings
    @invitations = Current.account.invitations
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

  def send_test_email
    if NotificationMailer.test_email(Current.user).deliver_now
      Notification.create(message: 'This is a test for email', notification_type: "Alert")
      flash[:notice] = "Test email sent successfully!"
    else
      flash[:alert] = "Failed to send test email."
    end

    respond_to do |format|
      format.html { redirect_to settings_user_path(Current.user), notice: 'Settings updated successfully.' }
      format.turbo_stream
    end
  end

  def send_test_text
    NotificationService.send_sms(Current.user.phone, "This is a test.")
    Notification.create(message: 'This is a test for text', notification_type: "Alert")

    respond_to do |format|
      format.html { redirect_to settings_user_path(Current.user), notice: 'Settings updated successfully.' }
      format.turbo_stream
    end
  end

  private

  def check_limit
    return if Current.user.blank? #If the user is not signed in yet, first time don't check limits.
    unless Current.account.can_create_user?
      redirect_to settings_user_path(Current.user), alert: "You’ve reached your limit. Upgrade to add more users."
      return
    end
  end

  # Strong parameters to permit user inputs
  def user_params
    params.require(:user).permit(:name, :phone, :email_address, :password, :password_confirmation, :invitation_token)
  end  
end
