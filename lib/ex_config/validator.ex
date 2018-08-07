defmodule ExConfig.Validator do
  @moduledoc """
  Helper tools for validating and creating fallback values for options
  """

  @env_prefix_regex ~r/^[A-Z][A-Z0-9_]*$/
  @default_valid_environments ~w(dev test beta prod)a

  @doc """
  Given opts, raise on bad values, fill defaults for missing values, and
  return the normalized opts.
  """
  def validate_opts!(mod, opts) do
    opts
    |> Keyword.put(:app, validate_app!(mod, opts))
    |> Keyword.put(:env_prefix, validate_env_prefix!(mod, opts))
    |> Keyword.put(:valid_environments, validate_valid_environments!(mod, opts))
    |> Keyword.put(:sections, validate_sections!(mod, opts))
  end

  def validate_app!(mod, opts) do
    case Keyword.fetch(opts, :app) do
      {:ok, app} when is_atom(app) ->
        app

      {:ok, not_atom} ->
        raise ArgumentError, "Invalid `:app`: #{not_atom}"

      :error ->
        mod
        |> Module.split()
        |> Enum.take(1)
        |> hd()
        |> Macro.underscore()
        |> String.to_atom()
    end
  end

  def validate_env_prefix!(mod, opts) do
    with {:ok, val} when byte_size(val) > 0 <- Keyword.fetch(opts, :env_prefix),
         {_, true} <- {val, Regex.match?(@env_prefix_regex, val)} do
      val
    else
      {:ok, val} ->
        raise ArgumentError, "Invalid `:env_prefix`: #{inspect(val)}"

      {val, false} ->
        raise ArgumentError, "Invalid `:env_prefix`: #{inspect(val)}"

      :error ->
        mod |> Module.split() |> Enum.take(1) |> hd() |> String.upcase()
    end
  end

  def validate_valid_environments!(_, opts) do
    case Keyword.fetch(opts, :valid_environments) do
      {:ok, envs} when envs != [] ->
        validate_all_atoms!(envs, "env")
        envs

      :error ->
        @default_valid_environments
    end
  end

  def validate_sections!(_, opts) do
    case Keyword.fetch(opts, :sections) do
      {:ok, sections} ->
        validate_all_atoms!(sections, "section")
        sections

      :error ->
        []
    end
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
