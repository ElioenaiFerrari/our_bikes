defmodule OurBikes.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  @roles ~w(admin user)

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:role, :string)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password_hash, :role])
    |> validate_required([:name, :email, :password_hash, :role])
    |> validate_format(:email, ~r/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    |> validate_inclusion(:role, @roles)
  end
end
