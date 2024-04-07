defmodule OurBikes.Bikes.Bike do
  use Ecto.Schema
  import Ecto.Changeset
  alias OurBikes.Platforms.Platform
  alias OurBikes.Users.User
  @status ~w(available reserved in_use)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:id, :status, :price, :platform_id]}
  schema "bikes" do
    field(:status, :string, default: "available")
    field(:price, :integer)
    belongs_to(:platform, Platform, foreign_key: :platform_id)
    belongs_to(:user, User, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bike, attrs) do
    bike
    |> cast(attrs, [:price, :platform_id, :status, :user_id])
    |> validate_required([:price, :platform_id])
    |> validate_inclusion(:status, @status)
  end
end
