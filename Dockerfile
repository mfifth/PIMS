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

# Set production-specific environment variables
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# --------------------------------------
# Build stage (to compile gems, assets)
# --------------------------------------
FROM base AS build

# Install libraries needed to build native extensions (e.g. pg)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libyaml-dev \
      pkg-config \
      libpq-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy Gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Precompile bootsnap for faster boot
RUN bundle exec bootsnap precompile --gemfile

# Copy full application code
COPY . .

# Precompile app code for bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets (skip master key check by using dummy secret)
# RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Optional cleanup (after build)
RUN rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git


# --------------------------------------
# Final runtime image
# --------------------------------------
FROM base

# Copy gems and app code from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint handles DB setup etc.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Default web server command (can override at runtime)
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
