class PagesController < ApplicationController
	skip_before_action :require_authentication
    def home
			redirect_to '/dashboard' if Current.user.present?
    end
end
