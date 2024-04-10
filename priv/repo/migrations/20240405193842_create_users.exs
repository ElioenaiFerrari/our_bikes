defmodule OurBikes.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: true) do
      add(:name, :string)
      add(:email, :string)
      add(:password_hash, :string)
      add(:role, :string)

      timestamps(type: :utc_datetime)
    end
  end
end
