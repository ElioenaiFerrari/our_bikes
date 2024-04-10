defmodule OurBikes.Users.User do
  @moduledoc """
  The schema for the User resource.

  This module defines the schema for the User resource. It uses the Ecto.Schema module to
  define the fields and relationships of the User schema. It also defines a changeset function
  that is used to validate and cast parameters when creating or updating a User record.

  ## Attributes

  * `:id` - The unique identifier of the User.
  * `:name` - The name of the User.
  * `:email` - The email of the User.
  * `:password` - The password of the User.
  * `:password_hash` - The hashed password of the User.
  * `:role` - The role of the User.
  """
  use Ecto.Schema
  import Ecto.Changeset
  @roles ~w(admin user)

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:role, :string)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :role])
    |> validate_required([:name, :email, :password, :role])
    |> validate_format(:email, ~r/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    |> validate_inclusion(:role, @roles)
  end
end
