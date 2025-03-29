class AccountsController < ApplicationController
  def settings
  end

  def update_settings
    if Current.user.update(email_address: params[:email_address], 
                           phone: params[:phone], 
                           email_notification: params[:email_notification],
                           text_notification: params[:text_notification])

      respond_to do |format|
        format.html { redirect_back fallback_location: '/', notice: 'Settings updated successfully.' }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream
      end
    end
  end
end
