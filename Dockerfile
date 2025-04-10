# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
FROM ruby:$RUBY_VERSION-slim AS base

# Set working directory
WORKDIR /rails

# Install base system packages needed at runtime
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips \
      sqlite3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Environment variables
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Allow passing master key for asset precompilation
ARG RAILS_MASTER_KEY
ENV RAILS_MASTER_KEY=$RAILS_MASTER_KEY

# --------------------------------------
# Build stage (to compile gems, assets)
# --------------------------------------
FROM base AS build

# Install libraries needed to build native extensions
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libyaml-dev \
      pkg-config \
      libpq-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Precompile gems with bootsnap
RUN bundle exec bootsnap precompile --gemfile

# Copy full application
COPY . .

# Ensure scripts are executable
RUN chmod +x bin/*

# Precompile app code
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets (requires master key if credentials used)
RUN ./bin/rails assets:precompile

# Optional cleanup
RUN rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git


# --------------------------------------
# Final runtime image
# --------------------------------------
FROM base

# Install runtime dependencies (e.g., git if needed by any gems)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy gems and app from build
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Ensure scripts are executable
RUN chmod +x bin/*

# Create non-root user and set permissions
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start app server (simplified)
EXPOSE 80
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
