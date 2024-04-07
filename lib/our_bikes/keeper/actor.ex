defmodule OurBikes.Keeper.Actor do
  use GenServer, restart: :transient
  alias OurBikes.Keeper.Registry
  alias OurBikes.Users.{User}
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

      {:noreply, Keyword.delete(state, :reserve)}
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
    reserve = %{
      bike_id: bike_id,
      platform_id: platform_id,
      reserved_at: :os.system_time(:millisecond)
    }

    case Keyword.has_key?(state, :reserve) do
      true ->
        Logger.info("you already reserved a bike")
        {:reply, {:error, :you_already_reserved_a_bike}, state}

      false ->
        Logger.info("bike #{bike_id} in platform #{platform_id} reserved")
        {:ok, reserve_time_ref} = :timer.send_interval(5_000, self(), :check_reserve)

        state =
          state
          |> Keyword.put(:reserve, reserve)
          |> Keyword.put(:reserve_time_ref, reserve_time_ref)

        {:reply, {:ok, reserve}, state}
    end
  end

  @impl true
  def handle_call({:use, bike_id, platform_id}, _from, state) do
    using = %{
      bike_id: bike_id,
      platform_id: platform_id,
      picked_up_at: :os.system_time(:millisecond)
    }

    case Keyword.get(state, :reserve) do
      nil ->
        Logger.info("bike #{bike_id} in platform #{platform_id} not reserved")

        {:ok, using_time_ref} = :timer.send_interval(5_000, self(), :check_use)

        reserve_time_ref = Keyword.get(state, :reserve_time_ref)
        :timer.cancel(reserve_time_ref)

        {
          :reply,
          {:ok, using},
          state
          |> Keyword.delete(:reserve)
          |> Keyword.put(:using, using)
          |> Keyword.put(:using_time_ref, using_time_ref)
        }

      %{
        bike_id: ^bike_id,
        platform_id: ^platform_id
      } ->
        Logger.info("bike #{bike_id} in platform #{platform_id} using")

        {:ok, using_time_ref} = :timer.send_interval(5_000, self(), :check_use)
        reserve_time_ref = Keyword.get(state, :reserve_time_ref)
        :timer.cancel(reserve_time_ref)

        {
          :reply,
          {:ok, using},
          state
          |> Keyword.delete(:reserve)
          |> Keyword.put(:using, using)
          |> Keyword.put(:using_time_ref, using_time_ref)
        }

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
        using_time_ref = Keyword.get(state, :using_time_ref)
        :timer.cancel(using_time_ref)

        state =
          state
          |> Keyword.delete(:using)
          |> Keyword.put(:locked, %{
            bike_id: bike_id,
            platform_id: platform_id,
            locked_at: :os.system_time(:millisecond)
          })

        {
          :noreply,
          state
        }
    end
  end

  @impl true
  def terminate(_, _) do
    Logger.info("terminating actor")

    :normal
  end
end
