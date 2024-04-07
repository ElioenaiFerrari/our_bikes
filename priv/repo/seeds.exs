require Logger
alias OurBikes.{Platforms, Bikes, Users, Keeper}

{:ok, user1} =  Users.create_user(%{
  name: Faker.Name.name(),
  email: Faker.Internet.email(),
  password: Faker.Lorem.word(),
  role: "admin"
})

{:ok, user2} =  Users.create_user(%{
  name: Faker.Name.name(),
  email: Faker.Internet.email(),
  password: Faker.Lorem.word(),
  role: "user"
})

{:ok, user3} =  Users.create_user(%{
  name: Faker.Name.name(),
  email: Faker.Internet.email(),
  password: Faker.Lorem.word(),
  role: "user"
})

{:ok, platform1} = Platforms.create_platform(%{
  name: "Platform 1",
  lat: 1.0,
  lng: 1.0
})

{:ok, platform2} = Platforms.create_platform(%{
  name: "Platform 2",
  lat: 2.0,
  lng: 2.0
})

{:ok, platform3} = Platforms.create_platform(%{
  name: "Platform 3",
  lat: 2.0,
  lng: 2.0
})

{:ok, bike1} = Bikes.create_bike(%{
  platform_id: platform1.id,
  price: 1000,
})

{:ok, bike2} = Bikes.create_bike(%{
  platform_id: platform2.id,
  price: 2000,
})


{:ok, bike3} = Bikes.create_bike(%{
  platform_id: platform3.id,
  price: 2000,
})


# Keeper.start_actor(user1)
# Keeper.start_actor(user2)
# Keeper.start_actor(user3)


# Logger.info("reserve")

# IO.inspect(Keeper.reserve(user1.id, bike1.id, platform2.id))
# IO.inspect(Keeper.reserve(user1.id, bike1.id, platform1.id))
# IO.inspect(Keeper.reserve(user1.id, bike1.id, platform2.id))
# IO.inspect(Keeper.reserve(user2.id, bike1.id, platform2.id))

# Logger.info("use")

# IO.inspect(Keeper.use(user1.id, bike1.id, platform2.id))
# IO.inspect(Keeper.use(user1.id, bike1.id, platform1.id))
# IO.inspect(Keeper.use(user1.id, bike1.id, platform2.id))
# IO.inspect(Keeper.use(user2.id, bike1.id, platform2.id))
# IO.inspect(Keeper.use(user2.id, bike2.id, platform2.id))
# IO.inspect(Keeper.use(user2.id, bike2.id, platform2.id))

# IO.inspect(Keeper.use(user3.id, bike3.id, platform3.id))
# IO.inspect(Keeper.give_back(user1.id, bike3.id, platform3.id))
# IO.inspect(Keeper.give_back(user3.id, bike3.id, platform3.id))
