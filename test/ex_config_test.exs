defmodule BoringDataSource1 do
  @behaviour ExConfig.DataSource
  def fetch(_, _, _, :a), do: {:ok, "letter a"}
  def fetch(_, _, _, _), do: :error
end

defmodule BoringDataSource2 do
  @behaviour ExConfig.DataSource
  def fetch(_, _, _, :a), do: {:ok, "second data source - letter a"}
  def fetch(_, _, _, :b), do: {:ok, "second data source - letter b"}
  def fetch(_, _, _, _), do: :error
end

defmodule MyApp.Config do
  use ExConfig, data_sources: [BoringDataSource1, BoringDataSource2]
end

defmodule MyApp.Config.CustomEnvironments do
  use ExConfig,
    valid_environments: [:mars, :pluto],
    data_sources: [BoringDataSource1]
end

defmodule MyApp.Config.AppOverride do
  use ExConfig, app: :different_app, data_sources: [BoringDataSource1]
end

defmodule MyApp.Config.EnvPrefixOverride do
  use ExConfig, env_prefix: "HAHA", data_sources: [BoringDataSource1]
end

defmodule MyApp.Config.Section do
  use ExConfig, sections: [:blah], data_sources: [BoringDataSource1]
end

defmodule MyApp.Config.SectionMacro do
  use ExConfig, data_sources: [BoringDataSource1]
  section(:blah)
end

defmodule ExConfigTest do
  use ExUnit.Case
  alias MyApp.Config

  alias MyApp.Config.{
    AppOverride,
    CustomEnvironments,
    EnvPrefixOverride,
    Section,
    SectionMacro
  }

  doctest ExConfig

  test "Config works" do
    assert {:ok, "letter a"} == Config.fetch(:some_section, :a)
    assert "letter a" == Config.fetch!(:some_section, :a)
    assert :error == Config.fetch(:some_section, :undefined_key)
    assert nil == Config.get(:some_section, :undefined_key)

    assert :my_default == Config.get(:some_section, :undefined_key, :my_default)
  end

  test "Application Environment" do
    System.delete_env("MYAPP_ENV")
    assert :dev == Config.env()
    System.put_env("MYAPP_ENV", "prod")
    assert :prod == Config.env()
    System.delete_env("MYAPP_ENV")
  end

  test "Custom Application Environments" do
    System.delete_env("MYAPP_ENV")
    assert :mars == CustomEnvironments.env()
    System.put_env("MYAPP_ENV", "pluto")
    assert :pluto == CustomEnvironments.env()
    System.delete_env("MYAPP_ENV")
  end

  test "Raises on bad environment" do
    System.put_env("MYAPP_ENV", "waaattt")
    assert_raise RuntimeError, fn -> Config.env() end
  end

  test "App can be overridden" do
    assert :different_app == AppOverride.app()
  end

  test "EnvPrefix can be overridden" do
    System.delete_env("HAHA_ENV")
    assert "HAHA" == EnvPrefixOverride.env_prefix()
    assert :dev == EnvPrefixOverride.env()
    System.put_env("HAHA_ENV", "beta")
    assert :beta == EnvPrefixOverride.env()
    System.delete_env("HAHA_ENV")
  end

  test "Section shortcuts" do
    assert "letter a" == Section.blah(:a)
  end

  test "Section shortcut macro" do
    assert "letter a" == SectionMacro.blah(:a)
  end

  test "Data source cascade logic" do
    assert "letter a" == Config.get(:whatever, :a)
    assert "second data source - letter b" == Config.get(:whatever, :b)
  end

  test "Exception is raised for missing value" do
    assert_raise RuntimeError, fn -> Section.blah!(:unset_key) end
    assert_raise RuntimeError, fn -> Section.fetch!(:whatever, :unset_key) end
  end
end
