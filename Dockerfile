# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install system dependencies
RUN sed -i 's/http:\/\/deb.debian.org/http:\/\/cloudfront.debian.net/g' /etc/apt/sources.list && \
    echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        libjemalloc2 \
        libvips \
        sqlite3 \
        libpq-dev \
        build-essential \
        git \
        libyaml-dev \
        pkg-config \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Set environment variables for production
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    RAILS_MASTER_KEY=""

FROM base AS build

# Install Ruby dependencies
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v '~> 2.5' && \
    bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Precompile Ruby gems
RUN bundle exec bootsnap precompile --gemfile

# Copy credentials (but NOT master.key)
COPY config/credentials.yml.enc config/

# Copy application files
COPY . .

# Precompile assets for production
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final image configuration
FROM base

# Copy everything from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create and set ownership for the rails user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails

# Switch to non-root user for security
USER 1000:1000

# Expose port and start the server
EXPOSE ${PORT:-3000}
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
