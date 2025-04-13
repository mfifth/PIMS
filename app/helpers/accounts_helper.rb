module AccountsHelper
  def product_limit(account)
		Subscription::PRODUCT_PLAN_LIMITS[account.subscription.plan]
	end
	
	def user_limit(account)
		Subscription::USER_PLAN_LIMITS[account.subscription.plan]
	end

	def location_limit(account)
		Subscription::LOCATION_PLAN_LIMITS[account.subscription.plan]
	end
end
