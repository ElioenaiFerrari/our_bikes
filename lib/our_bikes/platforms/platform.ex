defmodule OurBikes.Platforms.Platform do
  @moduledoc """
  The schema for the Platform resource.

  This module defines the schema for the Platform resource. It uses the Ecto.Schema module to
  define the fields and relationships of the Platform schema. It also defines a changeset function
  that is used to validate and cast parameters when creating or updating a Platform record.

  ## Attributes

  * `:id` - The unique identifier of the Platform.
  * `:name` - The name of the Platform.
  * `:lat` - The latitude of the Platform.
  * `:lng` - The longitude of the Platform.
  * `:bikes` - The list of bikes associated with the Platform.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias OurBikes.Bikes.Bike

  schema "platforms" do
    field(:lat, :float)
    field(:lng, :float)
    has_many(:bikes, Bike, foreign_key: :platform_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(platform, attrs) do
    platform
    |> cast(attrs, [:lat, :lng])
    |> validate_required([:lat, :lng])
  end
end
