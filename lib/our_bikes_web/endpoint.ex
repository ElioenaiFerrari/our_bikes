defmodule OurBikesWeb.Endpoint do
  use Plug.Builder

  plug(CORSPlug)
  plug(Plug.Logger, log: :debug)

  plug(
    Plug.Parsers,
    parsers: [{:json, json_encoder: Jason, json_decoder: Jason}]
  )

  plug(OurBikesWeb.Router)
end
