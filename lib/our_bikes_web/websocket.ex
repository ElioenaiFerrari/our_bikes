defmodule OurBikesWeb.Websocket do
  @behaviour :cowboy_websocket
  alias OurBikes.Users
  alias OurBikes.Users.User
  alias OurBikes.Keeper

  def init(req, state) do
    with %{user_id: user_id} <- Map.get(req, :bindings),
         %User{} = user <- Users.get_user(user_id),
         {:ok, _} <- Keeper.start_actor(user) do
      {:cowboy_websocket, req, state |> Keyword.put(:user_id, user_id)}
    else
      _ -> {:error, :unauthorized}
    end
  end

  def websocket_init(state), do: {:ok, state}
  def websocket_handle({:text, msg}, state), do: {:reply, {:text, "Echo: " <> msg}, state}
  def websocket_handle(_data, state), do: {:ok, state}
  def websocket_terminate(_reason, _state), do: :ok

  def websocket_info(any, state) do
    IO.inspect(any)
    {:ok, state}
  end

  def terminate(_, _, state) do
    state
    |> Keyword.fetch!(:user_id)
    |> Keeper.stop_actor()

    :ok
  end
end
