defmodule OurBikes.Platforms.Platform do
  @moduledoc """
  Documentation for `OurBikes.Platforms.Platform`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "platforms" do
    field(:lat, :float)
    field(:lng, :float)

    timestamps()
  end

  @doc false
  def changeset(platform, attrs) do
    platform
    |> cast(attrs, [:lat, :lng])
    |> validate_required([:lat, :lng])
  end
end
