VERSION 0.7

ARG --global --required BASE

ci:
  BUILD +test
  BUILD +lint
  BUILD +typespecs

setup-base:
  FROM hexpm/elixir:$BASE

  RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*
  RUN mix do local.rebar --force, \
             local.hex --force

  WORKDIR /idiom

  COPY mix.exs mix.lock .
  RUN mix deps.get

build:
  FROM +setup-base

  ENV MIX_ENV=test
  RUN mix deps.compile

  COPY --dir lib src priv .
  RUN mix compile --warnings-as-errors

test:
  FROM +build

  COPY --dir test .
  RUN mix test

lint:
  FROM +build

  COPY .credo.exs .formatter.exs .
  RUN mix format --check-formatted
  RUN mix credo

typespecs:
  FROM +build

  mix dialyzer
