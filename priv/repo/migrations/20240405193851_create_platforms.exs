defmodule OurBikes.Repo.Migrations.CreatePlatforms do
  use Ecto.Migration

  def change do
    create table(:platforms, primary_key: true) do
      add(:lat, :float)
      add(:lng, :float)

      timestamps(type: :utc_datetime)
    end
  end
end
