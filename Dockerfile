# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages including Node.js 18.x
RUN sed -i 's/http:\/\/deb.debian.org/http:\/\/cloudfront.debian.net/g' /etc/apt/sources.list && \
    echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 && \
    apt-get update -qq && \
    # Install curl first to fetch NodeSource script
    apt-get install --no-install-recommends -y curl ca-certificates && \
    # Add Node.js 18.x repository
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    # Install packages including modern Node.js
    apt-get install --no-install-recommends -y \
        nodejs \
        libjemalloc2 \
        libvips \
        sqlite3 \
        libpq-dev \
        build-essential \
        git \
        libyaml-dev \
        pkg-config && \
    # Clean up
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install application gems
COPY Gemfile Gemfile.lock ./

# Install the correct version of Bundler (e.g., version 2.5)
RUN gem install bundler -v '~> 2.5' && \
    bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Precompile assets to reduce startup time
RUN bundle exec bootsnap precompile --gemfile

# Copy package.json and package-lock.json for npm install
COPY package.json package-lock.json ./

# Install npm dependencies
RUN npm install

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["bin/rails", "server", "-b", "0.0.0.0"]