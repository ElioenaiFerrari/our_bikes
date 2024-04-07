defmodule OurBikes.Platforms.Platform do
  @moduledoc """
  Documentation for `OurBikes.Platforms.Platform`.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias OurBikes.Bikes.Bike

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "platforms" do
    field(:name, :string)
    field(:lat, :float)
    field(:lng, :float)
    has_many(:bikes, Bike, foreign_key: :platform_id)

    timestamps()
  end

  @doc false
  def changeset(platform, attrs) do
    platform
    |> cast(attrs, [:name, :lat, :lng])
    |> validate_required([:name, :lat, :lng])
  end
end
