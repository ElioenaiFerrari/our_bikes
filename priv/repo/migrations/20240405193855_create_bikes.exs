defmodule OurBikes.Repo.Migrations.CreateBikes do
  use Ecto.Migration

  def change do
    create table(:bikes, primary_key: true) do
      add(
        :platform_id,
        references(:platforms, on_update: :update_all, on_delete: :delete_all)
      )

      add(
        :user_id,
        references(:users, on_update: :update_all, on_delete: :delete_all),
        null: true
      )

      add(:type, :string)
      add(:status, :string)
      add(:price, :integer)
      add(:reserve_period, :integer)
      add(:use_period, :integer)

      timestamps(type: :utc_datetime)
    end
  end
end
