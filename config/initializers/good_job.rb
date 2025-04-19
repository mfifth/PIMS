if Rails.env.production?
	Rails.application.configure do
		config.active_job.queue_adapter = :good_job
	end

	# Ensure migrations run in production
	unless ActiveRecord::Base.connection.table_exists?('good_jobs')
		CreateGoodJobs.new.change
	end
end