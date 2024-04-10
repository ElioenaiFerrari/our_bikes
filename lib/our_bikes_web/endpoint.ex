defmodule OurBikesWeb.Endpoint do
  use Plug.Builder

  plug(CORSPlug)
  plug(Plug.Logger, log: :debug)

  plug(Plug.Static,
    at: "/",
    from: :our_bikes,
    gzip: false,
    only: ~w(index.html favicon.ico robots.txt assets images)
  )

  plug(
    Plug.Parsers,
    parsers: [{:json, json_encoder: Jason, json_decoder: Jason}]
  )

  plug(OurBikesWeb.Router)
end
