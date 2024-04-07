defmodule OurBikes.Platforms do
  @moduledoc """
  Documentation for `OurBikes.Platforms`.

  This module is responsible for managing platforms.

  Platforms are the physical locations where bikes are stored.
  """
  alias OurBikes.Repo
  alias OurBikes.Platforms.Platform

  def list_platforms do
    Platform
    |> Repo.all()
  end

  def get_platform(id) do
    Platform
    |> Repo.get(id)
  end

  def create_platform(attrs) do
    %Platform{}
    |> Platform.changeset(attrs)
    |> Repo.insert()
  end

  def update_platform(platform, attrs) do
    platform
    |> Platform.changeset(attrs)
    |> Repo.update()
  end

  def delete_platform(platform) do
    Repo.delete(platform)
  end
end
