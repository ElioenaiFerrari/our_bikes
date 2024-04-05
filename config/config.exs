import Config

config :our_bikes,
  ecto_repos: [OurBikes.Repo]

import_config "#{Mix.env()}.exs"
