class InvitationsController < ApplicationController
  before_action :set_invitation, only: [:destroy]

  def create
    @invitation = Invitation.new(invite_params)
    @invitation.account = Current.account
    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to settings_user_path(Current.user), notice: "Invitation sent!"
    else
      redirect_to settings_user_path(Current.user), alert: "Could not send invitation."
    end
  end

  def accept
    @invitation = Invitation.find_by(token: params[:token], accepted: false)
    if @invitation.nil?
      redirect_to root_path, alert: "Invalid or expired invitation."
      return
    end
  
    # Redirect to sign up form or show user creation with prefilled email
    redirect_to new_user_registration_path(token: @invitation.token)
  end

  def destroy
    @invitation.destroy
    flash[:notice] = "Invitation deleted successfully."
    respond_to do |format|
      format.html { redirect_to account_settings_path }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@invitation) }
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find(params[:id])
  end
  
  def invite_params
    params.require(:invitation).permit(:email, :role)
  end
end
