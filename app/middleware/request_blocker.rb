class RequestBlocker
  BLOCKED_PATHS = [/wp-includes/, /wp-admin/, /\.env/, /phpmyadmin/].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"]

    if BLOCKED_PATHS.any? { |pattern| path =~ pattern }
      [404, {}, ["Not Found"]]
    else
      @app.call(env)
    end
  end
end