defmodule OurBikes.Repo.Migrations.CreateBikes do
  use Ecto.Migration

  def change do
     create table(:bikes, primary_key: false) do
       add :id, :binary_id, primary_key: true
       add :platform_id, references(:platforms, on_update: :update_all, on_delete: :delete_all)
       add :status, :string
       add :price, :integer

       timestamps()
     end
  end
end
