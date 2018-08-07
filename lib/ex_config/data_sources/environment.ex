defmodule ExConfig.EnvironmentDataSource do
  @moduledoc """
  Data source for getting values from environment variables

  Note that the `app` is not used. If the app is `:skylab`, the section is
  `:some_service`, and the key is `:base_url`, then the environment variable
  we'll look to would be `SOME_SERVICE_BASE_URL`.
  """

  @behaviour ExConfig.DataSource

  @impl true
  def fetch(_mod, _app, section, key) do
    [section, key]
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.upcase/1)
    |> Enum.join("_")
    |> System.get_env()
    |> case do
      nil -> :error
      val -> {:ok, val}
    end
  end
end
