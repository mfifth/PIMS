class PagesController < ApplicationController
	skip_before_action :require_authentication

	def home
		redirect_to '/dashboard' if Current.user.present?
	end

	def contact_us
	end

	def contact_us_create
		name = params[:name]
		email = params[:email]
		message = params[:message]
		
		if email.present? && message.present?
			ContactMailer.contact_email(name, email, message).deliver_now
			redirect_to root_path, notice: "Thank you for your message! We'll get back to you soon."
		else
			flash[:alert] = "Please fill in all required fields."
			render :new
		end
	end
end
