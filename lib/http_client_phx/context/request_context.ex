defmodule HttpClientPhx.Context.RequestsContext do
  @moduledoc """
  Contexto para manejar las peticiones y colecciones guardadas.
  """

  import Ecto.Query, warn: false
  alias HttpClientPhx.Repo
  alias HttpClientPhx.Schemas.Request
  alias HttpClientPhx.Schemas.Collection

  @doc """
  Devuelve la lista de peticiones.
  """
  def list_requests do
    Repo.all(Request)
  end

  @doc """
  Obtiene una petición por su ID.
  """
  def get_request(id) do
    case Repo.get(Request, id) do
      nil -> {:error, :not_found}
      request -> {:ok, request}
    end
  end

  @doc """
  Crea una nueva petición.
  """
  def create_request(attrs) do
    %Request{}
    |> Request.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Actualiza una petición.
  """
  def update_request(id, attrs) do
    with {:ok, request} <- get_request(id) do
      request
      |> Request.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Elimina una petición.
  """
  def delete_request(id) do
    with {:ok, request} <- get_request(id) do
      Repo.delete(request)
      {:ok, request}
    end
  end

  @doc """
  Devuelve la lista de colecciones.
  """
  def list_collections do
    Repo.all(Collection)
  end

  @doc """
  Obtiene una colección por su ID.
  """
  def get_collection(id) do
    case Repo.get(Collection, id) do
      nil -> {:error, :not_found}
      collection -> {:ok, collection}
    end
  end

  @doc """
  Crea una nueva colección.
  """
  def create_collection(attrs) do
    %Collection{}
    |> Collection.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Actualiza una colección.
  """
  def update_collection(id, attrs) do
    with {:ok, collection} <- get_collection(id) do
      collection
      |> Collection.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Elimina una colección.
  """
  def delete_collection(id) do
    with {:ok, collection} <- get_collection(id) do
      Repo.delete(collection)
      {:ok, collection}
    end
  end

  @doc """
  Obtiene todas las peticiones de una colección.
  """
  def get_requests_by_collection(collection_id) do
    Request
    |> where(collection_id: ^collection_id)
    |> Repo.all()
  end

  @doc """
  Actualiza los datos de respuesta de una petición.
  """
  def update_request_response(id, status, headers, body) do
    with {:ok, request} <- get_request(id) do
      request
      |> Request.changeset(%{
        response_status: status,
        response_headers: headers,
        response_body: body
      })
      |> Repo.update()
    end
  end
end
