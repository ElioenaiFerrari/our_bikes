defmodule OurBikes.Repo.Migrations.CreatePlatforms do
  use Ecto.Migration

  def change do
    create table(:platforms) do
      add :lat, :float
      add :lng, :float

      timestamps()
    end
  end
end
