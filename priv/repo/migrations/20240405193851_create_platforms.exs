defmodule OurBikes.Repo.Migrations.CreatePlatforms do
  use Ecto.Migration

  def change do
    create table(:platforms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :lat, :float
      add :lng, :float

      timestamps()
    end
  end
end
