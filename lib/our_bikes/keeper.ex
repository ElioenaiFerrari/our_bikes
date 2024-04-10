defmodule OurBikes.Keeper do
  use DynamicSupervisor
  alias OurBikes.Keeper.{Actor, Registry}
  alias OurBikes.Bikes
  require Logger

  def start_link(opts) do
    state = DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)

    recover_state()

    state
  end

  defp recover_state() do
    bikes = Bikes.list_no_available_bikes()
    Logger.info("recovering state for #{Enum.count(bikes)} bikes")
    Enum.each(bikes, &start_actor(&1.user))
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_actor(user) do
    case Registry.lookup(user.id) do
      nil -> DynamicSupervisor.start_child(__MODULE__, {Actor, user: user})
      _ -> {:error, :already_started}
    end
  end

  def reserve(user_id, bike_id, platform_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> Actor.reserve(pid, bike_id, platform_id)
    end
  end

  def use(user_id, bike_id, platform_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> Actor.use(pid, bike_id, platform_id)
    end
  end

  def give_back(user_id, bike_id, platform_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> Actor.give_back(pid, bike_id, platform_id)
    end
  end

  def stop_actor(user_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end

    Registry.unregister(user_id)
  end

  def state(user_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> :sys.get_state(pid)
    end
  end
end
