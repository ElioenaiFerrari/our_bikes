defmodule OurBikes.Keeper.Actor do
  @moduledoc """
  The Actor module is responsible for managing the lifecycle of the actors that represent the users of the system.

  This module uses the GenServer module to manage the lifecycle of the actors that represent the users of the system. It provides functions to reserve, use, and give back bikes.

  ## Attributes

  * `:id` - The unique identifier of the User.
  * `:user` - The User that the actor represents.
  * `:reserve_time_ref` - The reference to the timer that checks the reservation period.
  * `:using_time_ref` - The reference to the timer that checks the using period.
  * `:reserve_period` - The period in seconds that a bike can be reserved.
  * `:use_period` - The period in seconds that a bike can be used.
  * `:check_period` - The period in seconds that the actor checks the reservation and using periods.
  """
  use GenServer, restart: :transient
  alias OurBikes.Keeper.Registry
  alias OurBikes.Users.User
  alias OurBikes.Bikes
  alias OurBikes.Bikes.Bike

  require Logger

  # Check every 1 minute
  @check_period :timer.minutes(1)

  def start_link(opts) do
    %User{id: id} = Keyword.fetch!(opts, :user) || raise ArgumentError, "missing :user option"

    # parent_pid =
    #   Keyword.fetch!(opts, :parent_pid) || raise ArgumentError, "missing :parent_pid option"

    GenServer.start_link(__MODULE__, opts, name: Registry.via(id))
  end

  @doc """
  Reserves a bike for the given user.
  """
  def reserve(pid, bike_id, platform_id) do
    GenServer.call(pid, {:reserve, bike_id, platform_id})
  end

  @doc """
  Uses a bike for the given user.
  """
  def use(pid, bike_id, platform_id) do
    GenServer.call(pid, {:use, bike_id, platform_id}, 60_000)
  end

  @doc """
  Gives back a bike for the given user.
  """
  def give_back(pid, bike_id, platform_id) do
    GenServer.call(pid, {:give_back, bike_id, platform_id})
  end

  @impl true
  def init(opts) do
    user = Keyword.fetch!(opts, :user)

    opts =
      case Bikes.get_bike_by_user_id(user.id) do
        nil ->
          Logger.info("keeper started for user #{user.id} without bike")
          opts

        %Bike{status: "reserved"} = bike ->
          Logger.info("keeper started for user #{user.id} with reserved bike #{bike.id}")
          Process.send(self(), :check_reserve, [])
          {:ok, reserve_time_ref} = :timer.send_interval(@check_period, self(), :check_reserve)
          Keyword.put(opts, :reserve_time_ref, reserve_time_ref)

        %Bike{status: "in_use"} = bike ->
          Logger.info("keeper started for user #{user.id} with using bike #{bike.id}")
          Process.send(self(), :check_use, [])
          {:ok, using_time_ref} = :timer.send_interval(@check_period, self(), :check_use)
          Keyword.put(opts, :using_time_ref, using_time_ref)
      end

    {:ok, opts}
  end

  @impl true
  def handle_info(:check_reserve, state) do
    Logger.info("checking reservation")

    with %User{} = user <- Keyword.fetch!(state, :user),
         _ <- Logger.info("user found: #{inspect(user)}"),
         %Bike{
           updated_at: updated_at,
           status: "reserved",
           reserve_period: reserve_period
         } = bike <-
           Bikes.get_bike_by_user_id(user.id),
         _ <- Logger.info("bike found: #{inspect(bike)}") do
      diff_seconds =
        updated_at
        |> DateTime.diff(DateTime.utc_now())
        |> abs()

      Logger.info("reserve diff_seconds: #{diff_seconds}, reservation_period: #{reserve_period}")

      if diff_seconds >= reserve_period do
        Logger.info("bike #{bike.id} in platform #{bike.platform_id} reservation expired")

        with reserve_time_ref <- Keyword.get(state, :reserve_time_ref),
             {:ok, _bike} <- Bikes.give_back_bike(bike, bike.platform_id),
             state <- Keyword.delete(state, :reserve_time_ref),
             {:ok, _} <- :timer.cancel(reserve_time_ref) do
          Logger.warning("bike #{bike.id} in platform #{bike.platform_id} given back")

          {:noreply, state}
        end
      else
        Logger.info("bike #{bike.id} in platform #{bike.platform_id} reservation still valid")

        {:noreply, state}
      end
    else
      err ->
        Logger.error("unexpected error #{inspect(err)}")

        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:check_use, state) do
    with %User{} = user <- Keyword.fetch!(state, :user),
         _ <- Logger.info("user found: #{inspect(user)}"),
         %Bike{
           updated_at: updated_at,
           status: "in_use",
           use_period: use_period
         } = bike <-
           Bikes.get_bike_by_user_id(user.id),
         _ <- Logger.info("bike found: #{inspect(bike)}") do
      diff_seconds =
        updated_at
        |> DateTime.diff(DateTime.utc_now())
        |> abs()

      Logger.info("using diff_seconds: #{diff_seconds}, use_period: #{use_period}")

      if diff_seconds >= use_period do
        Logger.warning("bike #{bike.id} in platform #{bike.platform_id} using expired")

        with using_time_ref <- Keyword.get(state, :using_time_ref),
             {:ok, _} <- :timer.cancel(using_time_ref),
             state <- Keyword.delete(state, :using_time_ref),
             {:ok, _} <- Bikes.give_back_bike(bike, bike.platform_id) do
          {:noreply, state}
        end
      else
        Logger.info("bike #{bike.id} in platform #{bike.platform_id} using still valid")

        {:noreply, state}
      end
    end
  end

  @impl true
  def handle_call({:reserve, bike_id, platform_id}, _from, state) do
    with %User{} = user <- Keyword.fetch!(state, :user),
         reserve <- %{
           bike_id: bike_id,
           platform_id: platform_id
         },
         nil <- Bikes.get_bike_by_user_id(user.id),
         %Bike{status: "available", platform_id: ^platform_id} = bike <- Bikes.get_bike(bike_id),
         {:ok, %Bike{status: "reserved"}} <- Bikes.reserve_bike(user.id, bike),
         {:ok, reserve_time_ref} <- :timer.send_interval(@check_period, self(), :check_reserve),
         state <-
           state
           |> Keyword.put(:reserve_time_ref, reserve_time_ref) do
      Logger.info("bike #{bike_id} in platform #{platform_id} reserved")
      {:reply, {:ok, reserve}, state}
    else
      {:error, reason} ->
        Logger.error("unexpected error #{inspect(reason)}")
        {:reply, {:error, reason}, state}

      %Bike{status: "available"} ->
        Logger.warning("invalid platform #{platform_id} for bike #{bike_id}")
        {:reply, {:error, :bike_not_in_platform}, state}

      %Bike{status: "reserved"} ->
        Logger.warning("you has already reserved a bike")
        {:reply, {:error, :single_reservation_per_user}, state}

      %Bike{status: "in_use"} ->
        Logger.warning("you has already using a bike")
        {:reply, {:error, :single_use_per_user}, state}
    end
  end

  @impl true
  def handle_call({:use, bike_id, platform_id}, _from, state) do
    user = Keyword.fetch!(state, :user)

    case Bikes.get_bike_by_user_id(user.id) do
      nil ->
        with %Bike{status: "available"} = bike <- Bikes.get_bike(bike_id),
             {:ok, _bike} <- Bikes.use_bike(user.id, bike),
             {:ok, using_time_ref} <- :timer.send_interval(@check_period, self(), :check_use),
             state <-
               state
               |> Keyword.delete(:reserve_time_ref)
               |> Keyword.put(:using_time_ref, using_time_ref) do
          Logger.info("using bike #{bike_id} in platform #{platform_id} without reservation")

          {
            :reply,
            {:ok, bike},
            state
          }
        else
          %Bike{status: "in_use"} ->
            Logger.warning("bike #{bike_id} in platform #{platform_id} already in use")

            {
              :reply,
              {:error, :already_in_use},
              state
            }

          %Bike{
            status: "reserved",
            id: ^bike_id,
            platform_id: ^platform_id,
            user_id: user_id
          } = bike ->
            with true <- user_id == user.id,
                 {:ok, _bike} <- Bikes.use_bike(user.id, bike),
                 {:ok, using_time_ref} <- :timer.send_interval(@check_period, self(), :check_use),
                 state <-
                   state
                   |> Keyword.delete(:reserve_time_ref)
                   |> Keyword.put(:using_time_ref, using_time_ref) do
              Logger.info("using bike #{bike_id} in platform #{platform_id} with reservation")

              {
                :reply,
                {:ok, bike},
                state
              }
            else
              {:error, reason} ->
                Logger.error("unexpected error #{inspect(reason)}")

                {
                  :reply,
                  {:error, reason},
                  state
                }

              false ->
                Logger.info(
                  "wrong user #{user.id} for bike #{bike_id} in platform #{platform_id}"
                )

                {
                  :reply,
                  {:error, :reserved_by_another_user},
                  state
                }
            end

          {:error, reason} ->
            Logger.error("unexpected error #{inspect(reason)}")

            {
              :reply,
              {:error, reason},
              state
            }
        end

      %Bike{
        id: ^bike_id,
        platform_id: ^platform_id,
        user_id: user_id
      } = bike ->
        with true <- user_id == user.id,
             %Bike{status: "reserved"} <- bike,
             {:ok, _} <- Bikes.use_bike(user.id, bike),
             reserve_time_ref <- Keyword.get(state, :reserve_time_ref),
             {:ok, _} <- :timer.cancel(reserve_time_ref),
             {:ok, using_time_ref} <- :timer.send_interval(@check_period, self(), :check_use),
             state <-
               state
               |> Keyword.delete(:reserve_time_ref)
               |> Keyword.put(:using_time_ref, using_time_ref) do
          Logger.info("using bike #{bike_id} in platform #{platform_id} with reservation")

          {
            :reply,
            {:ok, bike},
            state
          }
        else
          false ->
            Logger.info("wrong user #{user.id} for bike #{bike_id} in platform #{platform_id}")

            {
              :reply,
              {:error, :reserved_by_another_user},
              state
            }

          %Bike{status: "in_use"} ->
            Logger.info(
              "user #{user.id} already using bike #{bike_id} in platform #{platform_id}"
            )

            {
              :reply,
              {:error, :single_use_per_user},
              state
            }

          {:error, reason} ->
            Logger.info("bike #{bike_id} in platform #{platform_id} already in use")

            {
              :reply,
              {:error, reason},
              state
            }
        end

      %Bike{status: "reserved"} ->
        Logger.info("you has pending reservation for bike #{bike_id} in platform #{platform_id}")

        {
          :reply,
          {:error, :pending_reservation},
          state
        }

      %Bike{status: "in_use"} ->
        Logger.info("you has already using a bike")

        {
          :reply,
          {:error, :single_use_per_user},
          state
        }

      err ->
        Logger.error("unexpected error #{inspect(err)}")

        {
          :reply,
          {:error, :unexpected_error},
          state
        }
    end
  end

  @impl true
  def handle_call({:give_back, bike_id, platform_id}, _from, state) do
    user = Keyword.fetch!(state, :user)

    case Bikes.get_bike_by_user_id(user.id) do
      nil ->
        {:reply, {:error, :not_reserved}, state}

      %Bike{
        id: ^bike_id,
        platform_id: ^platform_id,
        status: "in_use"
      } = bike ->
        with using_time_ref <- Keyword.get(state, :using_time_ref),
             {:ok, _} <- :timer.cancel(using_time_ref),
             {:ok, bike} <- Bikes.give_back_bike(bike, platform_id),
             state <- Keyword.delete(state, :using_time_ref) do
          Logger.info("bike #{bike_id} in platform #{platform_id} given back")

          {
            :reply,
            {:ok, bike},
            state
          }
        end

      %Bike{
        id: ^bike_id,
        platform_id: ^platform_id,
        status: "reserved"
      } ->
        Logger.warning("bike #{bike_id} in platform #{platform_id} not in use")

        {
          :reply,
          {:error, :not_reserved},
          state
        }

      %Bike{} ->
        Logger.warning("wrong user #{user.id} for bike #{bike_id} in platform #{platform_id}")

        {
          :reply,
          {:error, :reserved_by_another_user},
          state
        }
    end
  end

  @impl true
  def terminate(reason, _) do
    Logger.error("terminating with reason #{inspect(reason)}")

    :normal
  end
end
