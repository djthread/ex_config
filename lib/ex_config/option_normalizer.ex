defmodule ExConfig.OptionNormalizer do
  @moduledoc """
  Helper tools for validating and creating fallback values for options
  """

  @env_prefix_regex ~r/^[A-Z][A-Z0-9_]*$/
  @default_valid_environments ~w(dev test beta prod)a

  # The default data sources to poll, in order
  @data_sources [
    ExConfig.EnvironmentDataSource,
    ExConfig.EnvConfigDataSource,
    ExConfig.ApplicationEnvironmentDataSource
  ]

  @type opts :: Keyword.t()

  @doc """
  Given opts, raise on bad values, fill defaults for missing values, and
  return the normalized opts.
  """
  @spec normalize_opts!(opts) :: opts
  def normalize_opts!(opts) do
    opts
    |> Keyword.put(:app, normalize_app!(opts))
    |> Keyword.put(:env_prefix, normalize_env_prefix!(opts))
    |> Keyword.put(:valid_environments, normalize_valid_environments!(opts))
    |> Keyword.put(:sections, normalize_sections!(opts))
    |> Keyword.put(:data_sources, normalize_data_sources!(opts))
  end

  def normalize_app!(opts) do
    case Keyword.fetch(opts, :app) do
      {:ok, app} when is_atom(app) ->
        app

      {:ok, not_atom} ->
        raise ArgumentError, "Invalid `:app`: #{not_atom}"

      :error ->
        opts
        |> Keyword.get(:module)
        |> Module.split()
        |> Enum.take(1)
        |> hd()
        |> Macro.underscore()
        |> String.to_atom()
    end
  end

  def normalize_env_prefix!(opts) do
    with {:ok, val} when byte_size(val) > 0 <- Keyword.fetch(opts, :env_prefix),
         {_, true} <- {val, Regex.match?(@env_prefix_regex, val)} do
      val
    else
      {:ok, val} ->
        raise ArgumentError, "Invalid `:env_prefix`: #{inspect(val)}"

      {val, false} ->
        raise ArgumentError, "Invalid `:env_prefix`: #{inspect(val)}"

      :error ->
        opts
        |> Keyword.get(:module)
        |> Module.split()
        |> Enum.take(1)
        |> hd()
        |> String.upcase()
    end
  end

  def normalize_valid_environments!(opts) do
    case Keyword.fetch(opts, :valid_environments) do
      {:ok, envs} when envs != [] ->
        validate_all_atoms!(envs, "env")
        envs

      :error ->
        @default_valid_environments
    end
  end

  def normalize_sections!(opts) do
    case Keyword.fetch(opts, :sections) do
      {:ok, sections} ->
        validate_all_atoms!(sections, "section")
        sections

      :error ->
        []
    end
  end

  def normalize_data_sources!(opts) do
    data_sources = Keyword.get(opts, :data_sources, @data_sources)

    Enum.each(data_sources, fn ds ->
      behaviours = Keyword.get(ds.module_info(:attributes), :behaviour, [])

      if ExConfig.DataSource not in behaviours do
        raise ArgumentError, """
        Data source does not implement `ExConfig.DataSource` behaviour: \
        #{ds}\
        """
      end
    end)

    data_sources
  end

  defp validate_all_atoms!(atoms, name) when is_list(atoms) do
    Enum.each(atoms, fn a ->
      is_atom(a) || raise ArgumentError, "Invalid #{name} atom: #{inspect(a)}"
    end)
  end

  defp validate_all_atoms!(atoms, name) do
    raise ArgumentError, "Invalid #{name} atom list: #{inspect(atoms)}"
  end
end
