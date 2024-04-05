defmodule OurBikes.Repo do
  use Ecto.Repo,
    otp_app: :our_bikes,
    adapter: Ecto.Adapters.SQLite3
end
