class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern

  before_action :set_locale
  before_action :check_trial_status, if: :account_present?

  def set_locale
    I18n.locale = Current.user&.locale || params[:locale].presence || session[:locale].presence || I18n.default_locale
    session[:locale] = I18n.locale
  end

  def require_admin!
    unless Current.user&.admin?
      redirect_to root_path, alert: t('permission_denied')
    end
  end

  private

  def default_url_options
    { locale: I18n.locale }
  end

  def account_present?
    Current.account.present?
  end

  def check_trial_status
    subscription = Current.account&.subscription
    return unless subscription
  
    if subscription.trialing? && subscription.expired?
      subscription.update!(status: "expired", plan: "free")
  
      flash[:alert] = t('notifications.free_trial_end')
    end
  end
end
