require Logger
alias OurBikes.{Platforms, Bikes, Users, Keeper}

{:ok, user} =  Users.create_user(%{
  name: Faker.Name.name(),
  email: Faker.Internet.email(),
  password: Faker.Lorem.word(),
  role: "admin"
})

{:ok, platform} = Platforms.create_platform(%{
  name: "Platform 1",
  lat: 1.0,
  lng: 1.0
})

{:ok, bike1} = Bikes.create_bike(%{
  platform_id: platform.id,
  price: 1000,
})

{:ok, bike2} = Bikes.create_bike(%{
  platform_id: platform.id,
  price: 2000,
})


{:ok, bike3} = Bikes.create_bike(%{
  platform_id: platform.id,
  price: 2000,
})

Logger.info("user_id: #{user.id}, platform_id: #{platform.id}")
