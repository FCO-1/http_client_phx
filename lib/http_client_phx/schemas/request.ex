defmodule HttpClientPhx.Schemas.Request do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "request_http"
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "requests" do
    field :name, :string
    field :method, :string
    field :url, :string
    field :headers, {:array, :map}, default: []
    field :body, :string
    field :response_body, :string
    field :response_headers, {:array, :map}, default: []
    field :response_status, :integer
    field :collection_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [:name, :method, :url, :headers, :body, :response_body, :response_headers, :response_status, :collection_id])
    |> validate_required([:name, :method, :url])
  end
end
