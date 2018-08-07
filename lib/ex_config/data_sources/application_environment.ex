defmodule ExConfig.ApplicationEnvironmentDataSource do
  @moduledoc """
  Data source for getting values from the application environment
  """

  @behaviour ExConfig.DataSource

  @impl true
  def fetch(_mod, app, section, key) do
    case Application.fetch_env(app, section) do
      {:ok, config} when is_list(config) ->
        Keyword.fetch(config, key)

      _ ->
        :error
    end
  end
end
