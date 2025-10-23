class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new

    if params[:token].present?
      invitation = Invitation.find_by(token: params[:token])
      @user.email_address = invitation&.email
      @user.admin = params[:admin]
    end
  end

  def show
  end

  def create
    @user = User.new(user_params.except(:invitation_token))
    invitation = Invitation.find_by(token: params[:user][:invitation_token]) if params[:user][:invitation_token].present?

    if @user.save
      if invitation
        invitation.account.users << @user
        invitation.update(accepted: true, confirmed_at: Time.current)
        @user.update(confirmed_at: Time.current)
        start_new_session_for(@user)
        redirect_to dashboard_path, notice: t('notifications.account_created')
      else
        @user.update(confirmed_at: Time.current)
        start_new_session_for(@user)
        redirect_to dashboard_path, notice: t('notifications.account_created')
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
      session[:locale] = Current.user.locale
      respond_to do |format|
        format.html { redirect_back fallback_location: '/', notice: t('notifications.updated_settings') }
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
      Notification.create(message: t('notifications.email_test'), notification_type: "Alert")
      flash[:notice] = t('notifications.email_notice')
    else
      flash[:alert] = t('notifications.failed_test_email')
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def send_test_text
    NotificationService.send_sms(Current.user.phone, t('notifications.test_text'))
    Notification.create(message: t('notifications.test_text_notification'), notification_type: "Alert")

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  # Strong parameters to permit user inputs
  def user_params
    params.require(:user).permit(:name, :phone, :email_address, :accepted_terms,
    :password, :password_confirmation, :invitation_token, :email_notification, :text_notification, :locale)
  end  
end
