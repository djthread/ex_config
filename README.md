# ExConfig

ExConfig makes configuration management in Elixir easier.

See the `ExConfig` module documentation for an explanation of the library.

## Installation

Add `:ex_config` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_config,
     git: "https://github.com/djthread/ex_config.git",
     branch: "master"}
  ]
end
```

## Usage

```elixir
use Mix.Config

config :my_app, :foo_service, base_url: "https://foo/"
config :my_app, :baz_service, timeout: 10_000
```

```elixir
defmodule MyApp.Config do
  use ExConfig, sections: [:foo_service]

  # Same meaning as `use` option
  section :another
end

alias MyApp.Config

Config.foo_service!(:base_url) #=> "https://foo/"
Config.foo_service(:something_unset) #=> nil
Config.another(:unset_thing) #=> nil
Config.fetch(:baz_service, :timeout) #=> 10000
```
