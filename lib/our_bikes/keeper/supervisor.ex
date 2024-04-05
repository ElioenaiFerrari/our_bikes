defmodule OurBikes.Keeper.Supervisor do
  use DynamicSupervisor
  alias OurBikes.Keeper.{Actor, Registry}

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_actor(user) do
    DynamicSupervisor.start_child(__MODULE__, {Actor, user: user})
  end

  def reserve(user_id, bike_id, platform_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> Actor.reserve(pid, bike_id, platform_id)
    end
  end

  def unlock(user_id, bike_id, platform_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> Actor.unlock(pid, bike_id, platform_id)
    end
  end

  def lock(user_id, bike_id, platform_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> Actor.lock(pid, bike_id, platform_id)
    end
  end

  def stop_actor(user_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end
end
