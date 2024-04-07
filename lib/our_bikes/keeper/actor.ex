defmodule OurBikes.Keeper.Actor do
  use GenServer, restart: :transient
  alias OurBikes.Keeper.Registry
  alias OurBikes.Users
  alias OurBikes.Users.User
  alias OurBikes.Bikes
  alias OurBikes.Bikes.Bike
  alias OurBikes.Platforms
  alias OurBikes.Platforms.Platform

  require Logger

  @reservation_period :timer.minutes(10)
  @use_period :timer.minutes(45)

  def start_link(opts) do
    %User{id: id} = Keyword.fetch!(opts, :user) || raise ArgumentError, "missing :user option"

    GenServer.start_link(__MODULE__, opts, name: Registry.via(id))
  end

  def reserve(pid, bike_id, platform_id) do
    GenServer.call(pid, {:reserve, bike_id, platform_id})
  end

  def use(pid, bike_id, platform_id) do
    GenServer.call(pid, {:use, bike_id, platform_id})
  end

  def give_back(pid, bike_id, platform_id) do
    GenServer.cast(pid, {:give_back, bike_id, platform_id})
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def handle_info(:check_reserve, state) do
    %{
      bike_id: bike_id,
      platform_id: platform_id,
      reserved_at: reserved_at
    } = Keyword.get(state, :reserve)

    now = :os.system_time(:millisecond)

    if now - reserved_at > @reservation_period do
      Logger.info("bike #{bike_id} in platform #{platform_id} reservation expired")

      reserve_time_ref = Keyword.get(state, :reserve_time_ref)
      :timer.cancel(reserve_time_ref)

      with %Bike{status: "reserved"} = bike <- Bikes.get_bike(bike_id),
           {:ok, _bike} <- Bikes.give_back_bike(bike, platform_id) do
        Logger.info("bike #{bike_id} in platform #{platform_id} given back")

        {:noreply, Keyword.delete(state, :reserve)}
      end
    else
      Logger.info("bike #{bike_id} in platform #{platform_id} reservation still valid")

      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:check_use, state) do
    %{
      bike_id: bike_id,
      platform_id: platform_id,
      picked_up_at: picked_up_at
    } = Keyword.get(state, :using)

    now = :os.system_time(:millisecond)

    if now - picked_up_at > @use_period do
      Logger.info("bike #{bike_id} in platform #{platform_id} using expired")

      using_time_ref = Keyword.get(state, :using_time_ref)
      :timer.cancel(using_time_ref)

      {:noreply, Keyword.delete(state, :using)}
    else
      Logger.info("bike #{bike_id} in platform #{platform_id} using still valid")

      {:noreply, state}
    end
  end

  @impl true
  def handle_call({:reserve, bike_id, platform_id}, _from, state) do
    with reserve <- %{
           bike_id: bike_id,
           platform_id: platform_id,
           reserved_at: :os.system_time(:millisecond)
         },
         false <- Keyword.has_key?(state, :reserve),
         %Bike{status: "available", platform_id: ^platform_id} = bike <- Bikes.get_bike(bike_id),
         {:ok, %Bike{status: "reserved"}} <- Bikes.reserve_bike(bike),
         {:ok, reserve_time_ref} <- :timer.send_interval(5_000, self(), :check_reserve),
         state <-
           state
           |> Keyword.put(:reserve, reserve)
           |> Keyword.put(:reserve_time_ref, reserve_time_ref) do
      Logger.info("bike #{bike_id} in platform #{platform_id} reserved")
      {:reply, {:ok, reserve}, state}
    else
      true ->
        Logger.info("single reservation per user")
        {:reply, {:error, :single_reservation_per_user}, state}

      {:error, reason} ->
        Logger.info("bike #{bike_id} in platform #{platform_id} already reserved")
        {:reply, {:error, reason}, state}

      %Bike{status: "available"} ->
        Logger.info("invalid platform #{platform_id} for bike #{bike_id}")
        {:reply, {:error, :invalid_platform}, state}

      %Bike{status: "reserved"} ->
        Logger.info("bike #{bike_id} in platform #{platform_id} already reserved")
        {:reply, {:error, :already_reserved}, state}
    end
  end

  @impl true
  def handle_call({:use, bike_id, platform_id}, _from, state) do
    case Keyword.get(state, :reserve) do
      nil ->
        Logger.info("bike #{bike_id} in platform #{platform_id} not reserved")

        with using <- %{
               bike_id: bike_id,
               platform_id: platform_id,
               picked_up_at: :os.system_time(:millisecond)
             },
             {:ok, using_time_ref} <- :timer.send_interval(5_000, self(), :check_use),
             reserve_time_ref <- Keyword.get(state, :reserve_time_ref),
             {:ok, _} <- :timer.cancel(reserve_time_ref),
             %Bike{status: "available"} = bike <- Bikes.get_bike(bike_id),
             {:ok, _bike} <- Bikes.use_bike(bike),
             state <-
               state
               |> Keyword.delete(:reserve)
               |> Keyword.put(:using, using)
               |> Keyword.put(:using_time_ref, using_time_ref) do
          Logger.info("bike #{bike_id} in platform #{platform_id} reserved")

          {
            :reply,
            {:ok, using},
            state
          }
        end

      %{
        bike_id: ^bike_id,
        platform_id: ^platform_id
      } ->
        Logger.info("bike #{bike_id} in platform #{platform_id} using")

        with using <- %{
               bike_id: bike_id,
               platform_id: platform_id,
               picked_up_at: :os.system_time(:millisecond)
             },
             {:ok, using_time_ref} <- :timer.send_interval(5_000, self(), :check_use),
             reserve_time_ref <- Keyword.get(state, :reserve_time_ref),
             {:ok, _} <- :timer.cancel(reserve_time_ref),
             %Bike{status: "reserved"} <- Bikes.get_bike(bike_id),
             state <-
               state
               |> Keyword.delete(:reserve)
               |> Keyword.put(:using, using)
               |> Keyword.put(:using_time_ref, using_time_ref) do
          Logger.info("bike #{bike_id} in platform #{platform_id} reserved")

          {
            :reply,
            {:ok, using},
            state
          }
        end

      _ ->
        Logger.info("wrong bike #{bike_id} in platform #{platform_id} reserved")

        {
          :reply,
          {:error, :wrong_bike},
          state
        }
    end
  end

  @impl true
  def handle_cast({:give_back, bike_id, platform_id}, state) do
    Logger.info("give back bike #{bike_id} in platform #{platform_id}")

    case Keyword.get(state, :using) do
      nil ->
        {:noreply, state}

      %{
        bike_id: ^bike_id,
        platform_id: ^platform_id
      } ->
        with using_time_ref <- Keyword.get(state, :using_time_ref),
             {:ok, _} <- :timer.cancel(using_time_ref),
             %Bike{status: "in_use"} = bike <- Bikes.get_bike(bike_id),
             {:ok, _bike} <- Bikes.give_back_bike(bike, platform_id) do
          Logger.info("bike #{bike_id} in platform #{platform_id} given back")

          state =
            state
            |> Keyword.delete(:using)
            |> Keyword.put(:picked_up, %{
              bike_id: bike_id,
              platform_id: platform_id,
              picked_up_at: :os.system_time(:millisecond)
            })

          {
            :noreply,
            state
          }
        end
    end
  end

  @impl true
  def terminate(_, _) do
    Logger.info("terminating actor")

    :normal
  end
end
