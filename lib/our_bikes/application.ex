defmodule OurBikes.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OurBikes.Repo,
      {Registry, keys: :unique, name: OurBikes.Keeper.Registry},
      {OurBikes.Keeper, []},
      {
        Plug.Cowboy,
        scheme: :http, plug: OurBikesWeb.Endpoint, options: [port: 4000], dispatch: dispatch()
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OurBikes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {
        :_,
        [
          {"/ws/[...]", OurBikesWeb.Websocket, []},
          {:_, Plug.Cowboy.Handler, {OurBikesWeb.Endpoint, []}}
        ]
      }
    ]
  end
end
