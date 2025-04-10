# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages including Node.js 18.x
RUN sed -i 's/http:\/\/deb.debian.org/http:\/\/cloudfront.debian.net/g' /etc/apt/sources.list && \
    echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y curl ca-certificates && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
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
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

FROM base AS build

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v '~> 2.5' && \
    bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

RUN bundle exec bootsnap precompile --gemfile

COPY package.json package-lock.json ./
RUN npm install

COPY . .
RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Fix permissions and entrypoint executable flag
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails && \
    chmod +x /rails/bin/docker-entrypoint

USER 1000:1000

# ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Use PORT environment variable (Render provides this)
EXPOSE ${PORT:-3000}
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "${PORT:-3000}"]