# syntax=docker/dockerfile:1

FROM ruby:3.4-bookworm AS base
WORKDIR /app
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    libpq-dev build-essential curl && rm -rf /var/lib/apt/lists/*
ENV BUNDLE_PATH=/usr/local/bundle
ENV BUNDLE_WITHOUT=""

FROM base AS build
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 \
 && rm -rf ~/.bundle/cache "${BUNDLE_PATH}"/ruby/*/cache
COPY . .
RUN bundle exec bootsnap precompile --gemfile app/ lib/ || true

FROM base AS runtime
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    PORT=3000
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
RUN useradd --create-home --shell /bin/bash rails \
 && chown -R rails:rails /app
USER rails
EXPOSE 3000
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3000"]
