defmodule OurBikes.Bikes.Bike do
  use Ecto.Schema
  import Ecto.Changeset
  alias OurBikes.{Platform, User}

  schema "bikes" do
    field(:name, :string)
    field(:price, :integer)
    belongs_to(:platform, Platform, foreign_key: :platform_id)
    belongs_to(:user, User, foreign_key: :user_id)

    timestamps()
  end

  @doc false
  def changeset(bike, attrs) do
    bike
    |> cast(attrs, [:name, :price, :platform_id, :user_id])
    |> validate_required([:name, :price, :platform_id, :user_id])
  end
end
