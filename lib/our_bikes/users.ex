defmodule OurBikes.Users do
  @moduledoc """
  Documentation for `OurBikes.Users`.

  This module is responsible for managing users.

  Users are the people who use the bikes.
  """
  alias OurBikes.Repo
  alias OurBikes.Users.User

  def list_users do
    User
    |> Repo.all()
  end

  def get_user(id) do
    User
    |> Repo.get(id)
  end

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(user) do
    Repo.delete(user)
  end
end
