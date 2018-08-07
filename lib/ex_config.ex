defmodule ExConfig do
  @moduledoc """
  Module enhancer for creating a nice place to get configuration data for
  your application

  To use, create a new module with something like

      defmodule MyApp.Config do
        use ExConfig
      end

  Configs under `:my_app` can be had via `MyApp.Config`'s `&fetch/2`,
  `&fetch!/2`, and `&get/3`.

  ## `use` Options

  The following options can be passed as a keyword list to the `use ExConfig`
  statement:

  * `:app` - The app atom. If undefined, this is assumed to be the first part
    of the using module's namespace, transformed with `&Macro.underscore/1`.
  * `:env_prefix` - A string which should be combined with "_ENV" to form the
    prefix of environment variables that are looked up. This is assumed to be
    first part of the using module's namespace, transformed with
    `&String.upcase/1`.
  * `:valid_environments` - A list of atoms which are the environment settings
    that can be set (in string form, of course) in the application environment
    variable (eg. `SKYLAB_ENV`)
  * `:sections` - A list of atoms which are the config sections that should
    have functions of the same names dynamically added to the module. (if
    :foo_service is in the list, then `&foo_service/1` and `&foo_service!/1`
    will be defined.)
  * `:data_sources` - A list of data source modules, in the order that they
    should be evaluated to resolve any config values. By default, the order is:
    * `ExConfig.EnvironmentDataSource`
    * `ExConfig.EnvConfigDataSource`
    * `ExConfig.ApplicationEnvironmentDataSource`

  ## Macros

  Inside your config module, you may use the following macros.

  * `section(atom)` - Shortcut functions will be defined to allow easier access
    to the section by the name of the given atom. For instance, if the module
    has `section(:thing)`, then:
    * `&thing/1` will be defined. Call it with `:base_url` to get the same
      value as `get(:thing, :base_url)`.
    * `&thing!/1` will be defined. Call it with `:base_url` to get the same
      value as `fetch!(:thing, :base_url)`.

  ## Application Environment

  This library adds the concept of the application's (runtime) environment.
  The `:valid_environments` list has all the possible values and the first
  entry will be the default environment if none is set. In order to set one,
  simply define the relevant environment variable. For instance, if your
  `:env_prefix` is `"SKYLAB"` (and `:prod` is included in your
  `:valid_environments` list) then setting your `SKYLAB_ENV` environment
  variable to `"prod"` would set the application environment to `:prod`.

  This value is used when finding the needed value in the
  `ExConfig.EnvConfigDataSource` step of the cascading logic.

  ## Cascading Logic

  The cascading logic for finding a config value with the `section`
  `:some_service` and `key` `:base_url` would be as follows. If any step comes
  back with a value, the rest of the steps will be skipped and the value
  returned.

  * Look in the `SOME_SERVICE_BASE_URL` environment variable
  * Look in the application environment under `:my_app`, `:some_service`,
    `:env_configs` for a keyword list. Use the application environment atom as
    the key to find a keyword list which should then include the `key`.
  * Look in the application environment under `:my_app`, `:some_service`,
    `:base_url`
  """

  alias ExConfig.Validator

  # The data sources to poll, in order
  @data_sources [
    ExConfig.EnvironmentDataSource,
    ExConfig.EnvConfigDataSource,
    ExConfig.ApplicationEnvironmentDataSource
  ]

  defmacro __using__(opts) do
    opts = Validator.validate_opts!(__CALLER__.module, opts)

    quote do
      import ExConfig, only: [section: 1]

      @doc "Get the configured data sources"
      @spec data_sources :: [module]
      def data_sources do
        unquote(Keyword.get(opts, :data_sources, @data_sources))
      end

      @doc "Get the application environment"
      @spec env :: String.t()
      def env, do: ExConfig.get_env(unquote(opts))

      @doc "Get the atom for the app's config namespace"
      @spec app :: atom
      def app, do: unquote(Keyword.get(opts, :app))

      @doc "Get the all-caps string for the environment variables' prefix"
      @spec env_prefix :: String.t()
      def env_prefix, do: unquote(Keyword.get(opts, :env_prefix))

      @doc "Fetch a configuration key; raise if unset"
      @spec fetch!(atom, atom) :: any | no_return
      def fetch!(section, key),
        do: ExConfig.fetch!(__MODULE__, app(), section, key)

      @doc "Fetch a configuration key"
      @spec fetch(atom, atom) :: {:ok, any} | :error
      def fetch(section, key),
        do: ExConfig.fetch(__MODULE__, app(), section, key)

      @doc "Get a configuration key"
      @spec get(atom, atom, any) :: any
      def get(section, key, default \\ nil),
        do: ExConfig.get(__MODULE__, app(), section, key, default)

      Module.eval_quoted(
        __ENV__,
        Enum.map(
          unquote(Keyword.get(opts, :sections)),
          &ExConfig.section_fn_generator/1
        )
      )
    end
  end

  @doc """
  Create some shortcut functions for a given section
  """
  defmacro section(section) do
    section_fn_generator(section)
  end

  @doc "Get the application (runtime) environment"
  @spec get_env(list) :: atom
  def get_env(opts) do
    valid = Keyword.get(opts, :valid_environments)
    prefix = Keyword.get(opts, :env_prefix)

    case System.get_env("#{prefix}_ENV") do
      nil ->
        hd(valid)

      val ->
        if val in Enum.map(valid, &to_string/1),
          do: String.to_atom(val),
          else:
            raise("""
            Invalid #{prefix}_ENV (#{val}). Add `:#{val}` to the
            `:valid_environments` option.
            """)
    end
  end

  @doc "Get a configuration value, raise if unset"
  @spec fetch!(module, atom, atom, atom) :: any | no_return
  def fetch!(mod, app, section, key) do
    case fetch(mod, app, section, key) do
      :error ->
        raise RuntimeError,
              "Couldn't get #{inspect(section)} config: #{inspect(key)}"

      {:ok, val} ->
        val
    end
  end

  @doc "Get a configuration value"
  @spec get(module, atom, atom, atom) :: any
  def get(mod, app, section, key, default \\ nil) do
    case fetch(mod, app, section, key) do
      {:ok, val} -> val
      :error -> default
    end
  end

  @doc "Fetch a configuration value"
  @spec fetch(module, atom, atom, atom) :: any
  def fetch(mod, app, section, key) do
    do_fetch(mod.data_sources(), mod, app, section, key)
  end

  @doc "Generates some section-specific functions"
  def section_fn_generator(sec) do
    quote do
      @doc "get a key from the `:#{unquote(sec)}` section"
      @spec unquote(sec)(atom) :: any
      def unquote(sec)(key, default \\ nil),
        do: get(unquote(sec), key, default)

      @doc "fetch a key from the `:#{unquote(sec)}` section"
      @spec unquote(:"#{sec}!")(atom) :: {:ok, any} | :error
      def unquote(:"#{sec}!")(key), do: fetch!(unquote(sec), key)
    end
  end

  defp do_fetch([source | tail], mod, app, section, key) do
    with :error <- source.fetch(mod, app, section, key) do
      do_fetch(tail, mod, app, section, key)
    end
  end

  defp do_fetch([], _, _, _, _) do
    :error
  end
end
