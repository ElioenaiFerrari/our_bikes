defmodule OurBikesWeb.Router do
  use Plug.Router
  alias OurBikesWeb.PlatformController

  plug(:match)
  plug(:dispatch)

  forward("/api/platforms", to: PlatformController)

  match _ do
    send_resp(conn, :not_found, "oops")
  end
end
