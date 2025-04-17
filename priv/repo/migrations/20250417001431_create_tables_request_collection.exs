defmodule HttpClientPhx.Repo.Migrations.CreateTablesRequestCollection do
  use Ecto.Migration

  def change do
    schema="request_http"
    execute "CREATE SCHEMA #{schema}", "DROP SCHEMA IF EXISTS #{schema}"


    create table(:collections, primary_key: false, prefix: schema) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps()
    end

    create table(:requests, primary_key: false, prefix: schema) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :method, :string, null: false
      add :url, :string, null: false
      add :headers, {:array, :map}, default: []
      add :body, :text
      add :response_body, :text
      add :response_headers, {:array, :map}, default: []
      add :response_status, :integer
      add :collection_id, references(:collections, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create index(:requests, [:collection_id], prefix: schema)
    create index(:requests, [:name], prefix: schema)
    create index(:requests, [:url, :name], prefix: schema)


  end
end
