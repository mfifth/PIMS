Rails.application.configure do
  config.active_job.queue_adapter = :good_job
  
  if Rails.env.production?
    config.good_job = {
      execution_mode: :external,    # Required for Render
      max_threads: 5,              # Match your Render DB connections
      enable_cron: false,          # Disable unless using cron
      shutdown_timeout: 25,        # Give jobs time to finish
      logger: Rails.logger         # Better logging
    }
  end
end