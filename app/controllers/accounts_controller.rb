class AccountsController < ApplicationController
  def settings
  end
  
  def update_settings
    ActiveRecord::Base.transaction do
      if Current.user.update!(email_address: params[:email], phone: params[:phone]) &&
         Current.account.update!(email_notification: !!params[:email_notification], 
         text_notification: !!params[:text_notification])
        redirect_back fallback_location: '/', notice: 'Settings updated successfully.'
      else
        render :edit
      end
    end
  end
end
