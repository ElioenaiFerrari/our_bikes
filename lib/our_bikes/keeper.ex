defmodule OurBikes.Keeper do
  @moduledoc """
  The Keeper module is responsible for managing the lifecycle of the actors that represent the users of the system.

  This module uses the DynamicSupervisor module to manage the lifecycle of the actors that represent the users of the system. It provides functions to start, stop, and query the state of the actors. It also provides functions to reserve, use, and give back bikes.
  """
  use DynamicSupervisor
  alias OurBikes.Keeper.{Actor, Registry}
  alias OurBikes.Bikes
  require Logger

  def start_link(opts) do
    state = DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)

    recover_state()

    state
  end

  @doc """
  Recovers the state of the actors that represent the users of the system.

  This function queries the database for bikes that are not available and starts an actor for each user that has a bike that is not available.
  """
  defp recover_state() do
    bikes = Bikes.list_no_available_bikes()
    Logger.info("recovering state for #{Enum.count(bikes)} bikes")
    Enum.each(bikes, &start_actor(&1.user))
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts an actor for the given user.

  This function starts an actor for the given user. If an actor is already running for the user, it returns an error.
  """
  def start_actor(user) do
    case Registry.lookup(user.id) do
      nil -> DynamicSupervisor.start_child(__MODULE__, {Actor, user: user})
      _ -> {:error, :already_started}
    end
  end

  @doc """
  Reserves a bike for the given user.
  """
  def reserve(user_id, bike_id, platform_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> Actor.reserve(pid, bike_id, platform_id)
    end
  end

  @doc """
  Uses a bike for the given user.
  """
  def use(user_id, bike_id, platform_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> Actor.use(pid, bike_id, platform_id)
    end
  end

  @doc """
  Gives back a bike for the given user.
  """
  def give_back(user_id, bike_id, platform_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> Actor.give_back(pid, bike_id, platform_id)
    end
  end

  @doc """
  Stops the actor for the given user.
  """
  def stop_actor(user_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end

    Registry.unregister(user_id)
  end

  @doc """
  Queries the state of the actor for the given user.
  """
  def state(user_id) do
    case Registry.lookup(user_id) do
      nil -> {:error, :not_found}
      pid -> :sys.get_state(pid)
    end
  end
end
