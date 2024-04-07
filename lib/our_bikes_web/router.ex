defmodule OurBikesWeb.Router do
  use Plug.Router

  plug(:match)
  plug(Plug.Logger, log: :debug)

  plug(
    Plug.Parsers,
    parsers: [{:json, json_encoder: Jason, json_decoder: Jason}]
  )

  plug(:dispatch)

  match _ do
    send_resp(conn, :not_found, "oops")
  end
end
