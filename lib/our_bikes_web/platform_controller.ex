defmodule OurBikesWeb.PlatformController do
  use Plug.Router
  alias OurBikes.Bikes

  plug(:match)
  plug(:dispatch)

  get "/:id/bikes" do
    bikes =
      conn
      |> Map.get(:params)
      |> Map.get("id")
      |> Bikes.list_bikes_by_platform_id()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, Jason.encode!(bikes))
  end
end
