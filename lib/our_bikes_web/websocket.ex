defmodule OurBikesWeb.Websocket do
  @behaviour :cowboy_websocket
  alias OurBikes.Users
  alias OurBikes.Users.User
  alias OurBikes.Keeper
  require Logger

  def init(
        %{qs: "user_id=" <> user_id} = req,
        state
      )
      when byte_size(user_id) > 0 do
    with %User{} = user <- Users.get_user(user_id),
         _ <- Logger.info("user found: #{inspect(user)}"),
         _ <- Keeper.start_actor(user) do
      {
        :cowboy_websocket,
        req,
        state |> Keyword.put(:user_id, user.id),
        %{idle_timeout: :infinity}
      }
    end
  end

  def init(_, _), do: {:error, :bad_request}

  defp handle(%{
         "type" => "reserve",
         "user_id" => user_id,
         "bike_id" => bike_id,
         "platform_id" => platform_id
       }) do
    case Keeper.reserve(user_id, bike_id, platform_id) do
      {:error, :already_reserved} -> %{"error" => "bike already reserved"}
      {:error, :already_in_use} -> %{"error" => "bike already in use"}
      {:error, :bike_not_in_platform} -> %{"error" => "bike not in platform"}
      {:error, :single_reservation_per_user} -> %{"error" => "single reservation per user"}
      {:error, :single_use_per_user} -> %{"error" => "single use per user"}
      {:ok, reserve} -> reserve
    end
  end

  defp handle(%{
         "type" => "use",
         "user_id" => user_id,
         "bike_id" => bike_id,
         "platform_id" => platform_id
       }) do
    case Keeper.use(user_id, bike_id, platform_id) do
      {:error, :not_reserved} -> %{"error" => "bike not reserved"}
      {:error, :reserved_by_another_user} -> %{"error" => "reserved by another user"}
      {:error, :single_use_per_user} -> %{"error" => "single use per user"}
      {:error, :pending_reservation} -> %{"error" => "pending reservation"}
      {:error, :bike_not_in_platform} -> %{"error" => "bike not in platform"}
      {:error, :already_in_use} -> %{"error" => "bike already in use"}
      {:ok, using} -> using
    end
  end

  defp handle(%{
         "type" => "give_back",
         "user_id" => user_id,
         "bike_id" => bike_id,
         "platform_id" => platform_id
       }) do
    case Keeper.give_back(user_id, bike_id, platform_id) do
      {:error, :not_reserved} -> %{"error" => "bike not reserved"}
      {:error, :reserved_by_another_user} -> %{"error" => "reserved by another user"}
      {:error, :not_in_use} -> %{"error" => "bike not in use"}
      {:error, :bike_not_in_platform} -> %{"error" => "bike not in platform"}
      {:ok, give_back} -> give_back
    end
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

  def websocket_info(_, state) do
    {:ok, state}
  end

  def terminate(_, _, state) do
    user_id =
      Keyword.fetch!(state, :user_id)

    Logger.info("websocket terminate for user #{user_id}")

    :ok
  end
end
