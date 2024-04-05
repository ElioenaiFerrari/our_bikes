defmodule OurBikesTest.KeeperTest.ActorTest do
  use ExUnit.Case, async: true
  alias OurBikes.Keeper.Actor
  alias OurBikes.User

  defp fake_user() do
    %User{
      id: Faker.UUID.v4(),
      name: Faker.Person.name(),
      email: Faker.Internet.email()
    }
  end

  describe "reserve/3" do
    test "when no has reserved a bike" do
      # Arrange
      user = fake_user()

      {:ok, pid} =
        Actor.start_link(user: user)

      bike_id = Faker.UUID.v4()
      platform_id = Faker.UUID.v4()

      # Act
      assert {
               :ok,
               %{
                 bike_id: ^bike_id,
                 platform_id: ^platform_id,
                 reserved_at: reserved_at
               }
             } = Actor.reserve(pid, bike_id, platform_id)
    end

    test "when has reserved a bike" do
      # Arrange
      user = fake_user()

      {:ok, pid} =
        Actor.start_link(user: user)

      bike_id = Faker.UUID.v4()
      platform_id = Faker.UUID.v4()

      # Act
      assert {
               :ok,
               %{
                 bike_id: ^bike_id,
                 platform_id: ^platform_id,
                 reserved_at: reserved_at
               }
             } = Actor.reserve(pid, bike_id, platform_id)

      other_bike_id = Faker.UUID.v4()
      other_platform_id = Faker.UUID.v4()

      # Act
      assert {:error, :you_already_reserved_a_bike} =
               Actor.reserve(pid, other_bike_id, other_platform_id)
    end
  end

  describe "use/3" do
    test "when no has reserved a bike" do
      # Arrange
      user = fake_user()

      {:ok, pid} =
        Actor.start_link(user: user)

      bike_id = Faker.UUID.v4()
      platform_id = Faker.UUID.v4()

      # Act
      assert {
               :ok,
               %{
                 bike_id: ^bike_id,
                 platform_id: ^platform_id,
                 picked_up_at: picked_up_at
               }
             } = Actor.use(pid, bike_id, platform_id)
    end

    test "when has reserved a bike" do
      # Arrange
      user = fake_user()

      {:ok, pid} =
        Actor.start_link(user: user)

      bike_id = Faker.UUID.v4()
      platform_id = Faker.UUID.v4()

      assert {
               :ok,
               %{
                 bike_id: ^bike_id,
                 platform_id: ^platform_id,
                 reserved_at: reserved_at
               }
             } = Actor.reserve(pid, bike_id, platform_id)

      # Act
      assert {
               :ok,
               %{
                 bike_id: ^bike_id,
                 platform_id: ^platform_id,
                 picked_up_at: picked_up_at
               }
             } = Actor.use(pid, bike_id, platform_id)
    end

    test "when has reserved a bike and try to use another bike" do
      # Arrange
      user = fake_user()

      {:ok, pid} =
        Actor.start_link(user: user)

      bike_id = Faker.UUID.v4()
      platform_id = Faker.UUID.v4()

      assert {
               :ok,
               %{
                 bike_id: ^bike_id,
                 platform_id: ^platform_id,
                 reserved_at: reserved_at
               }
             } = Actor.reserve(pid, bike_id, platform_id)

      # Act
      other_bike_id = Faker.UUID.v4()
      other_platform_id = Faker.UUID.v4()

      assert {
               :error,
               :wrong_bike
             } = Actor.use(pid, other_bike_id, other_platform_id)
    end
  end
end
