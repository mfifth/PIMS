if Rails.env.production? && !ENV["SKIP_DB"]
  Rails.application.configure do |config|
    config.active_job.queue_adapter = :good_job
    config.good_job.pool_size = 5
  end
  config.good_job.pool_size = 5
  begin
    # This will safely check the table without crashing if DB is unavailable
    ActiveRecord::Base.connection_pool.with_connection do |conn|
      unless conn.table_exists?('good_jobs')
        Rails.logger.info "[GoodJob] 'good_jobs' table does not exist."
      end
    end
  rescue => e
    Rails.logger.warn "[GoodJob] Skipping good_jobs check: #{e.class} - #{e.message}"
  end
end
