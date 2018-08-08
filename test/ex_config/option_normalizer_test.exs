defmodule NotADataSource do
end

defmodule ExConfig.OptionNormalizerTest do
  use ExUnit.Case
  alias ExConfig.OptionNormalizer, as: N

  test "normalize_opts!" do
    assert :i == Keyword.get(N.normalize_opts!(module: I.Like.It), :app)

    # Converting to a map because I don't care of the order
    assert %{
             app: :alright,
             module: Alright.Config,
             env_prefix: "ALRIGHT",
             valid_environments: ~w(good things here)a,
             sections: [:one],
             data_sources: [
               ExConfig.EnvironmentDataSource,
               ExConfig.EnvConfigDataSource,
               ExConfig.ApplicationEnvironmentDataSource
             ]
           } ==
             Enum.into(
               N.normalize_opts!(
                 module: Alright.Config,
                 valid_environments: [:good, :things, :here],
                 sections: [:one]
               ),
               %{}
             )
  end

  test "normalize_app!" do
    assert :foo == N.normalize_app!(app: :foo)
    assert :foo == N.normalize_app!(module: Foo.Config)

    assert_raise ArgumentError, fn ->
      N.normalize_app!(app: "not an atom")
    end
  end

  test "normalize_env_prefix!" do
    assert "BLA" == N.normalize_env_prefix!(env_prefix: "BLA")
    assert "ALB" == N.normalize_env_prefix!(module: ALB.TheConfig)

    assert_raise ArgumentError, fn ->
      N.normalize_env_prefix!(env_prefix: :not_a_string)
    end

    assert_raise ArgumentError, fn ->
      N.normalize_env_prefix!(env_prefix: "")
    end

    assert_raise ArgumentError, fn ->
      N.normalize_env_prefix!(env_prefix: "1BAD")
    end
  end

  test "normalize_valid_environments!" do
    assert 0 < length(N.normalize_valid_environments!([]))

    assert [:foo, :bar] ==
             N.normalize_valid_environments!(valid_environments: [:foo, :bar])

    assert_raise ArgumentError, fn ->
      N.normalize_valid_environments!(valid_environments: [:foo, "WAT"])
    end

    assert_raise ArgumentError, fn ->
      N.normalize_valid_environments!(valid_environments: "WATTT")
    end
  end

  test "normalize_sections!" do
    assert [] == N.normalize_sections!([])
    assert [:sec] == N.normalize_sections!(sections: [:sec])

    assert_raise ArgumentError, fn ->
      N.normalize_sections!(sections: "BAD")
    end

    assert_raise ArgumentError, fn ->
      N.normalize_sections!(sections: ["BAD"])
    end
  end

  test "normalize_data_sources!" do
    assert 0 < length(N.normalize_data_sources!([]))

    assert_raise ArgumentError, fn ->
      N.normalize_data_sources!(data_sources: [NotADataSource])
    end
  end
end
