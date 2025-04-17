defmodule HttpClientPhx.Schemas.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "request_http"
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "collections" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
