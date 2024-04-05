defmodule OurBikesTest.KeeperTest.ActorTest do
  use ExUnit.Case, async: true
  alias OurBikes.Keeper.Actor
  alias OurBikes.User

  describe "reserve/3" do
    test "reserves a bike" do
      {:ok, pid} =
        Actor.start_link(
          user: %User{
            id: Faker.UUID.v4(),
            name: Faker.Person.name(),
            email: Faker.Internet.email()
          }
        )
    end
  end
end
