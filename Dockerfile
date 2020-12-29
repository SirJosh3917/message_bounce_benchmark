FROM elixir:alpine AS build
ENV MIX_ENV prod
WORKDIR /app

# pull in just dependencies in one layer, so future changes of code don't have to do much
COPY mix.exs .
COPY mix.lock .
RUN mix local.hex --force && \
    mix deps.get && \
    mix deps.compile

# build all of code into a release
COPY . /app
RUN mix distillery.release && \
    mkdir /release && \
    tar -xzf /app/_build/prod/rel/message_bounce_benchmark/releases/0.1.0/message_bounce_benchmark.tar.gz -C /release

FROM alpine:latest
ENV REPLACE_OS_VARS true
WORKDIR /app

# `bash` is a required dependency for the built release to work
RUN apk update && \
    apk add --no-cache bash

COPY --from=build /release /app

CMD ["/app/bin/message_bounce_benchmark", "foreground"]
