module ApplicationHelper
	def square_connected?
		Current.account&.square_access_token.present? && Current.account&.square_merchant_id.present?
	end
end
