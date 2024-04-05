import Config

config :our_bikes, OurBikes.Repo,
  database: "our_bikes",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
