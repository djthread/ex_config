defmodule ExConfig.EnvConfigDataSource do
  @moduledoc """
  Data source for getting values from the environment-specific configurations
  in the application environment

  With the goal in mind of deploying the same build artifact to all
  environments, we would then need to have the same compiled application
  environment available in all environments. This data source reads from
  _application_ environment specific configuration.

  ## Example

      config :my_app, :some_service,
        env_configs: [
          dev: [base_url: "https://dev.service.endpoint/"],
          beta: [base_url: "https://beta.service.endpoint/"],
          prod: [base_url: "https://prod.service.endpoint/"]
        ]

  If the `MY_APP_ENV` is set to `"beta"`, then the application's environment
  is `:beta` and perhaps `MyApp.Config.get(:some_service, :base_url)` would
  return `"https://beta.env.service.endpoint/"`.
  """

  @behaviour ExConfig.DataSource

  @impl true
  def fetch(mod, app, section, key) do
    with {:ok, section_conf} when is_list(section_conf) <-
           Application.fetch_env(app, section),
         {:ok, env_configs} when is_list(env_configs) <-
           Keyword.fetch(section_conf, :env_configs),
         {:ok, env_config} when is_list(env_config) <-
           Keyword.fetch(env_configs, mod.env()) do
      Keyword.fetch(env_config, key)
    else
      _ -> :error
    end
  end
end
