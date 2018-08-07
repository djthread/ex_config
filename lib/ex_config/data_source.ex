defmodule ExConfig.DataSource do
  @moduledoc """
  Defines a behaviour which can get a configuration value
  """

  @callback fetch(atom, atom, atom, list) :: {:ok, any} | :error
end
