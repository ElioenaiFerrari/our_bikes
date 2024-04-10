defmodule OurBikes.Bikes.Bike do
  @moduledoc """
  The schema for the Bike resource.

  This module defines the schema for the Bike resource. It uses the Ecto.Schema module to
  define the fields and relationships of the Bike schema. It also defines a changeset function
  that is used to validate and cast parameters when creating or updating a Bike record.

  ## Attributes

  * `:id` - The unique identifier of the Bike.
  * `:status` - The status of the Bike.
  * `:price` - The price of the Bike.
  * `:platform_id` - The unique identifier of the Platform associated with the Bike.
  * `:user_id` - The unique identifier of the User associated with the Bike.
  * `:platform` - The Platform associated with the Bike.
  * `:user` - The User associated with the Bike.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias OurBikes.Platforms.Platform
  alias OurBikes.Users.User
  @status ~w(available reserved in_use)
  @types ~w(road mountain hybrid comfort electric)

  @derive {Jason.Encoder, only: [:id, :status, :price, :platform_id, :type]}
  schema "bikes" do
    field(:status, :string, default: "available")
    field(:price, :integer)
    field(:type, :string, default: "road")
    # 5 minutes in seconds
    field(:reserve_period, :integer, default: 300)
    # 45 minutes in seconds
    field(:use_period, :integer, default: 2700)
    belongs_to(:platform, Platform, foreign_key: :platform_id)
    belongs_to(:user, User, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bike, attrs) do
    bike
    |> cast(attrs, [:price, :platform_id, :status, :user_id, :type, :reserve_period, :use_period])
    |> validate_required([:price, :platform_id])
    |> validate_inclusion(:status, @status)
    |> validate_inclusion(:type, @types)
    |> validate_number(:price, greater_than_or_equal_to: 500)
    |> validate_number(:reserve_period, greater_than_or_equal_to: 300)
    |> validate_number(:use_period, greater_than_or_equal_to: 2700)
  end
end
