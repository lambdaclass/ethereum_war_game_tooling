FROM elixir:1.13-alpine

RUN apk --no-cache add \
  cargo
  # inotify-tools\
  # git

RUN mkdir /app
WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.lock mix.exs ./

# Get both dev and test env dependencies
RUN MIX_ENV="dev" mix do deps.get --only dev, deps.compile
# RUN MIX_ENV="test" mix do deps.get --only test, deps.compile

# Copy the source code to the docker image.
COPY . .

# Pre-compile dev & test environments
RUN MIX_ENV="dev" mix compile
# RUN MIX_ENV="test" mix compile

ENTRYPOINT "./startup.sh"
CMD iex -S mix
# CMD iex --sname wargame_tools --erl "-config sys.config -setcookie mycookie" -S mix

