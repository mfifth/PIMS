class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern

  before_action :set_locale
  before_action :check_trial_status, if: :account_present?

  def set_locale
    I18n.locale = Current.user&.locale || I18n.default_locale
  end

  def require_admin!
    unless Current.user&.admin?
      redirect_to root_path, alert: t('permission_denied')
    end
  end

  private

  def account_present?
    Current.account.present?
  end

  def check_trial_status
    return unless Current.account&.subscription
    subscription = Current.account.subscription
  
    if subscription.trialing? && subscription.expired?
      subscription.update!(status: "expired", plan: "free")
  
      redirect_to root_path, alert: "Your free trial has ended. Please choose a plan to continue."
    end
  end
end
