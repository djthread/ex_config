defmodule(ConfigInBetaEnv, do: def(env, do: :beta))
defmodule(ConfigInProdEnv, do: def(env, do: :prod))

defmodule ExConfig.EnvConfigDataSourceTest do
  use ExUnit.Case
  alias ExConfig.EnvConfigDataSource, as: DS

  @env_configs [beta: [some_key: "some value"]]

  test "fetch works" do
    Application.put_env(:my_app, :my_section, env_configs: @env_configs)

    assert {:ok, "some value"} ==
             DS.fetch(ConfigInBetaEnv, :my_app, :my_section, :some_key)

    assert :error ==
             DS.fetch(ConfigInBetaEnv, :my_app, :my_section, :some_other_key)

    assert :error == DS.fetch(ConfigInProdEnv, :my_app, :my_section, :some_key)
  end
end
