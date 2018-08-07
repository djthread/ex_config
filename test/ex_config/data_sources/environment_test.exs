defmodule ExConfig.EnvironmentDataSourceTest do
  use ExUnit.Case
  alias ExConfig.EnvironmentDataSource, as: DS

  test "it works" do
    System.put_env("MY_SERVICE_BASE_URL", "https://my.example.com/")

    assert {:ok, "https://my.example.com/"} ==
             DS.fetch(:_, :_, :my_service, :base_url)

    assert :error == DS.fetch(:_, :_, :my_service, :bla)
  end
end
