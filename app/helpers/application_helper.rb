module ApplicationHelper
	def square_connected?
		Current.account&.square_access_token.present? && Current.account&.square_merchant_id.present?
	end

	def clover_connected?
		Current.account&.clover_access_token.present? && Current.account&.clover_merchant_id.present?
	end

	def sidebar_link_class(path)
		base = "flex items-center font-semibold py-2 px-4 rounded-md hover:bg-ivory"
		request.path == path ? "#{base} bg-light-gray" : base
	end	
end
