class InvitationsController < ApplicationController
  before_action :set_invitation, only: [:destroy, :confirm]

  def create
    @invitation = Invitation.new(invite_params)
    @invitation.account = Current.account
    
    if @invitation.save
      redirect_to settings_user_path(Current.user), notice: "Invitation sent!"
    else
      redirect_to settings_user_path(Current.user), alert: "Could not send invitation."
    end
  end

  def accept
    @invitation = Invitation.find_by(token: params[:token], accepted: false)
    
    if @invitation.nil? || @invitation.expired?
      redirect_to root_path, alert: "Invalid or expired invitation."
      return
    end

    # Redirect to sign up with prefilled email if not confirmed
    unless @invitation.confirmed?
      redirect_to confirm_invitation_path(token: @invitation.token)
      return
    end

    # If already confirmed, proceed to registration
    redirect_to new_user_path(token: @invitation.token)
  end

  def confirm
    @invitation = Invitation.find_by(token: params[:token])
    
    if @invitation.present?
      if request.get?
        render 'confirm'
      elsif request.post?
        @invitation.confirm!
        InvitationMailer.invite(@invitation).deliver_later # Resend with confirmed status
        redirect_to new_user_path(token: @invitation.token), notice: "Invitation confirmed! Please complete your registration."
      end
    else
      redirect_to root_path, alert: "Invalid or expired invitation."
    end
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
    @invitation = Invitation.find_by(token: params[:token])
  end
  
  def invite_params
    params.require(:invitation).permit(:email, :role)
  end
end