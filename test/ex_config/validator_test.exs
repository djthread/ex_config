defmodule ExConfig.ValidatorTest do
  use ExUnit.Case
  alias ExConfig.Validator, as: V

  test "validate_opts!" do
    assert :i == Keyword.get(V.validate_opts!(I.Like.It, []), :app)

    # Converting to a map because I don't care of the order
    assert %{
             app: :alright,
             env_prefix: "ALRIGHT",
             valid_environments: ~w(good things here)a,
             sections: [:one]
           } ==
             Enum.into(
               V.validate_opts!(Alright.Config,
                 valid_environments: [:good, :things, :here],
                 sections: [:one]
               ),
               %{}
             )
  end

  test "validate_app!" do
    assert :foo == V.validate_app!(:_, app: :foo)
    assert :foo == V.validate_app!(Foo.Config, [])

    assert_raise ArgumentError, fn ->
      V.validate_app!(:_, app: "not an atom")
    end
  end

  test "validate_env_prefix!" do
    assert "BLA" == V.validate_env_prefix!(:_, env_prefix: "BLA")
    assert "ALB" == V.validate_env_prefix!(ALB.TheConfig, [])

    assert_raise ArgumentError, fn ->
      V.validate_env_prefix!(:_, env_prefix: :not_a_string)
    end

    assert_raise ArgumentError, fn ->
      V.validate_env_prefix!(:_, env_prefix: "")
    end

    assert_raise ArgumentError, fn ->
      V.validate_env_prefix!(:_, env_prefix: "1BAD")
    end
  end

  test "validate_valid_environments!" do
    assert 0 < length(V.validate_valid_environments!(:_, []))

    assert [:foo, :bar] ==
             V.validate_valid_environments!(:_, valid_environments: [:foo, :bar])

    assert_raise ArgumentError, fn ->
      V.validate_valid_environments!(:_, valid_environments: [:foo, "WAT"])
    end

    assert_raise ArgumentError, fn ->
      V.validate_valid_environments!(:_, valid_environments: "WATTT")
    end
  end

  test "validate_sections!" do
    assert [] == V.validate_sections!(:_, [])
    assert [:sec] == V.validate_sections!(:_, sections: [:sec])

    assert_raise ArgumentError, fn ->
      V.validate_sections!(:_, sections: "BAD")
    end

    assert_raise ArgumentError, fn ->
      V.validate_sections!(:_, sections: ["BAD"])
    end
  end
end
