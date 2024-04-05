defmodule OurBikesTest do
  use ExUnit.Case
  doctest OurBikes

  test "greets the world" do
    assert OurBikes.hello() == :world
  end
end
