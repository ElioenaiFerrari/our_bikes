defmodule OurBikes.Keeper.Actor do
  use GenServer, restart: :transient
  alias OurBikes.Keeper.Registry
  alias OurBikes.{User}
  require Logger

  @reservation_period :timer.minutes(10)
  @use_period :timer.minutes(45)

  def start_link(opts) do
    %User{id: id} = Keyword.fetch!(opts, :user) || raise ArgumentError, "missing :user option"

    GenServer.start_link(__MODULE__, opts, name: Registry.via(id))
  end

  @spec reserve(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, any(), any()) :: any()
  def reserve(pid, bike_id, platform_id) do
    GenServer.call(pid, {:reserve, bike_id, platform_id})
  end

  def unlock(pid, bike_id, platform_id) do
    GenServer.call(pid, {:unlock, bike_id, platform_id})
  end

  def lock(pid, bike_id, platform_id) do
    GenServer.cast(pid, {:lock, bike_id, platform_id})
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def handle_info({:check_reserve, bike_id, platform_id}, state) do
  end

  @impl true
  def handle_info({:check_use, bike_id, platform_id}, state) do
  end

  @impl true
  def handle_call({:reserve, bike_id, platform_id}, _from, state) do
    Logger.info("reserve bike #{bike_id} in platform #{platform_id}")

    state =
      Keyword.put(state, :reserve, %{
        bike_id: bike_id,
        platform_id: platform_id,
        reserved_at: :os.system_time(:millisecond)
      })

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:unlock, bike_id, platform_id}, _from, state) do
    Logger.info("unlock bike #{bike_id} in platform #{platform_id}")

    case Keyword.get(state, :reserve) do
      nil ->
        {:reply, {:ok, :unlocked},
         Keyword.put(state, :used, %{
           bike_id: bike_id,
           platform_id: platform_id,
           unlocked_at: :os.system_time(:millisecond)
         })}

      %{bike_id: bike_id, platform_id: platform_id} ->
        if bike_id == bike_id and platform_id == platform_id do
          {
            :reply,
            {:ok, :unlocked},
            state
            |> Keyword.delete(:reserve)
            |> Keyword.put(:used, %{
              bike_id: bike_id,
              platform_id: platform_id,
              unlocked_at: :os.system_time(:millisecond)
            })
          }
        else
          {
            :reply,
            {:error, :not_reserved},
            state
          }
        end
    end

    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:lock, bike_id, platform_id}, state) do
    Logger.info("lock bike #{bike_id} in platform #{platform_id}")

    case Keyword.get(state, :used) do
      nil ->
        {:noreply, state}

      %{bike_id: bike_id, platform_id: platform_id} ->
        if bike_id == bike_id and platform_id == platform_id do
          {
            :noreply,
            state
            |> Keyword.delete(:used)
            |> Keyword.put(:locked, %{
              bike_id: bike_id,
              platform_id: platform_id,
              locked_at: :os.system_time(:millisecond)
            })
          }
        else
          {:noreply, state}
        end
    end
  end

  @impl true
  def terminate(reason, state) do
  end
end
