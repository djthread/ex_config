defmodule ExConfig.ApplicationEnvironmentDataSourceTest do
  use ExUnit.Case
  alias ExConfig.ApplicationEnvironmentDataSource, as: DS

  test "fetch works" do
    Application.put_env(:my_app, :my_section, my_key: "teh value")

    assert {:ok, "teh value"} == DS.fetch(:_, :my_app, :my_section, :my_key)
    assert :error == DS.fetch(:_, :my_app, :my_section, :unset_key)
  end
end
