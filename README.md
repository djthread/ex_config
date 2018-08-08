# ExConfig

ExConfig makes configuration management in Elixir easier.

See the [`ExConfig` module documentation](https://git.rockfin.com/pages/marketing-web/ex_config/ExConfig.html) for an explanation of the library.


## Installation

Add `:ex_config` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_config,
     git: "https://git.rockfin.com/marketing-web/ex_config.git",
     branch: "stable"}
  ]
end
```

## Usage Examples

```elixir
use Mix.Config

config :my_app, :foo_service, base_url: "https://foo/"
config :my_app, :baz,
    color: "blue",
    env_configs: [
        prod: [color: "orange"]
    ]
```

```elixir
defmodule MyApp.Config do
  use ExConfig, sections: [:foo_service]

  # Same meaning as `use` option
  section :another
end

alias MyApp.Config

Config.env()                         #=> :dev
Config.foo_service!(:base_url)       #=> "https://foo/"
Config.get(:foo_service, :base_url)  #=> "https://foo/"
Config.get(:foo_service, :blah)      #=> nil
Config.foo_service(:something_unset) #=> nil
Config.another(:unset_thing)         #=> nil

Config.fetch(:baz, :color)           #=> {:ok, "blue"}
System.put_env("MYAPP_ENV", "prod")
Config.env()                         #=> :prod
Config.fetch(:baz, :color)           #=> {:ok, "orange"}
System.put_env("BAZ_COLOR", "pink")
Config.fetch(:baz, :color)           #=> {:ok, "pink"}
```
