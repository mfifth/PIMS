Rails.application.config.after_initialize do
	# This ensures controllers are available in development
	Dir.glob(Rails.root.join('app/javascript/controllers/**/*_controller.js')).each do |file|
			Rails.application.config.assets.precompile << file
  end
end