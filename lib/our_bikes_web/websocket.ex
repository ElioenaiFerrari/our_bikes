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

  defp handle(%{
         "type" => "reserve",
         "user_id" => user_id,
         "bike_id" => bike_id,
         "platform_id" => platform_id
       }) do
    Keeper.reserve(user_id, bike_id, platform_id)
  end

  defp handle(%{
         "type" => "use",
         "user_id" => user_id,
         "bike_id" => bike_id,
         "platform_id" => platform_id
       }) do
    Keeper.use(user_id, bike_id, platform_id)
  end

  defp handle(%{
         "type" => "give_back",
         "user_id" => user_id,
         "bike_id" => bike_id,
         "platform_id" => platform_id
       }) do
    Keeper.give_back(user_id, bike_id, platform_id)
  end

  def websocket_init(state), do: {:ok, state}

  def websocket_handle({:text, msg}, state) do
    user_id = state |> Keyword.fetch!(:user_id)

    payload =
      msg
      |> Jason.decode!()
      |> Map.put("user_id", user_id)

    result = handle(payload)
    {:reply, {:text, Jason.encode!(result)}, state}
  end

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
