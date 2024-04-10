defmodule OurBikesWeb.PlatformController do
  @moduledoc """
  Controller for the Platform resource.

  This controller is responsible for handling requests related to the Platform resource. It
  uses the Bikes module to interact with the database.

  ## Attributes

  * `:id` - The unique identifier of the Platform.
  * `:name` - The name of the Platform.
  * `:lat` - The latitude of the Platform.
  * `:lng` - The longitude of the Platform.
  * `:bikes` - The list of bikes associated with the Platform.
  """
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
