defmodule OurBikes.Repo.Migrations.CreateBikes do
  use Ecto.Migration

  def change do
     create table(:bikes) do
       add :platform_id, references(:platforms, on_update: :update_all, on_delete: :delete_all)
       add :user_id, references(:users, on_update: :update_all, on_delete: :delete_all)
       add :name, :string
       add :price, :integer

       timestamps()
     end
  end
end
