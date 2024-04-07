defmodule OurBikes.Bikes do
  @moduledoc """
  Documentation for `OurBikes.Bikes`.

  This module is responsible for managing bikes.

  Bikes are the vehicles that users can rent.
  """
  alias OurBikes.Repo
  alias OurBikes.Bikes.Bike

  def list_bikes do
    Bike
    |> Repo.all()
  end

  def get_bike(id) do
    Bike
    |> Repo.get(id)
  end

  def create_bike(attrs) do
    %Bike{}
    |> Bike.changeset(attrs)
    |> Repo.insert()
  end

  def update_bike(bike, attrs) do
    bike
    |> Bike.changeset(attrs)
    |> Repo.update()
  end

  def delete_bike(bike) do
    Repo.delete(bike)
  end

  def reserve_bike(bike) do
    bike
    |> Bike.changeset(%{status: "reserved"})
    |> Repo.update()
  end

  def use_bike(bike) do
    bike
    |> Bike.changeset(%{status: "in_use"})
    |> Repo.update()
  end

  def give_back_bike(bike, platform_id) do
    bike
    |> Bike.changeset(%{status: "available", platform_id: platform_id})
    |> Repo.update()
  end
end
