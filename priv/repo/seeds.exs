require Logger
alias OurBikes.{Platforms, Bikes, Users, Keeper}

{:ok, _} =  Users.create_user(%{
  name: Faker.Name.name(),
  email: Faker.Internet.email(),
  password: Faker.Lorem.word(),
  role: "admin"
})

{:ok, _} =  Users.create_user(%{
  name: Faker.Name.name(),
  email: Faker.Internet.email(),
  password: Faker.Lorem.word(),
  role: "user"
})

{:ok, platform} = Platforms.create_platform(%{
  lat: 1.0,
  lng: 1.0
})

{:ok, _} = Bikes.create_bike(%{
  platform_id: platform.id,
  price: 1000,
  type: "mountain"
})

{:ok, _} = Bikes.create_bike(%{
  platform_id: platform.id,
  price: 2000,
  type: "electric",
  # 10 minutes in seconds
  reserve_period: 600,
  # 1:30 minutes in seconds
  use_period: 5400
})


{:ok, _} = Bikes.create_bike(%{
  platform_id: platform.id,
  price: 2000,
  type: "comfort",
  # 5 minutes in seconds
  reserve_period: 300,
  # 2h in seconds
  use_period: 7200
})

{:ok, _} = Bikes.create_bike(%{
  platform_id: platform.id,
  price: 2000,
  type: "hybrid",
  # 1h in seconds
  use_period: 3600
})

{:ok, _} = Bikes.create_bike(%{
  platform_id: platform.id,
  price: 2000,
  type: "road"
})
