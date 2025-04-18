class InvitationsController < ApplicationController
  def create
    @invitation = Invitation.new(invite_params)
    @invitation.account = Current.account
    
    if @invitation.save
      redirect_to settings_user_path(Current.user), notice: t('notifications.invitation_sent')
    else
      redirect_to settings_user_path(Current.user), alert: t('notifications.invitation_error')
    end
  end

  def accept
    @invitation = Invitation.find_by(token: params[:token])
    
    # Handle invalid cases
    if @invitation.nil? || @invitation.expired? || @invitation.accepted?
      redirect_to root_path, alert: t('notifications.expired_invitation')
      return
    end

    # Auto-confirm and redirect to signup
    @invitation.confirm!
    redirect_to new_user_url(
      token: @invitation.token,
      email: @invitation.email
    ), notice: t('notifications.complete_registration')
  end

  def destroy
    @invitation = Invitation.find(params[:id])
    @user = User.find_by(email_address: @invitation.email)

    @invitation.destroy
    @user.destroy if @user

    flash[:notice] = t('notifications.removed_user')
    respond_to do |format|
      format.html { redirect_to account_settings_path }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@invitation) }
    end
  end

  private
  
  def invite_params
    params.require(:invitation).permit(:email, :role)
  end
end