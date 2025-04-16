defmodule HttpClientPhx.Requests do
  @moduledoc """
  Contexto para manejar las peticiones guardadas.
  """

  # Para simplificar, usaremos ETS para almacenar peticiones en memoria
  # En una aplicación real, usaríamos una base de datos

  @table_name :saved_requests

  @doc """
  Inicializa la tabla ETS para almacenar peticiones.
  """
  def init do
    :ets.new(@table_name, [:set, :public, :named_table])
    :ok
  end

  @doc """
  Crea una nueva petición.
  """
  def create_request(attrs) do
    id = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    request = Map.put(attrs, "id", id)

    :ets.insert(@table_name, {id, request})
    {:ok, request}
  end

  @doc """
  Obtiene todas las peticiones guardadas.
  """
  def list_requests do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_, request} -> request end)
  end

  @doc """
  Obtiene una petición por su ID.
  """
  def get_request(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, request}] -> {:ok, request}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Actualiza una petición existente.
  """
  def update_request(id, attrs) do
    with {:ok, request} <- get_request(id) do
      updated_request = Map.merge(request, attrs)
      :ets.insert(@table_name, {id, updated_request})
      {:ok, updated_request}
    end
  end

  @doc """
  Elimina una petición existente.
  """
  def delete_request(id) do
    :ets.delete(@table_name, id)
    :ok
  end

  @doc """
  Crea una colección de peticiones.
  """
  def create_collection(attrs) do
    id = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    collection = Map.put(attrs, "id", id)
    collection = Map.put_new(collection, "requests", [])

    :ets.insert(@table_name, {id, collection})
    {:ok, collection}
  end

  @doc """
  Añade una petición a una colección.
  """
  def add_request_to_collection(collection_id, request_id) do
    with {:ok, collection} <- get_request(collection_id),
         {:ok, _request} <- get_request(request_id) do
      requests = Map.get(collection, "requests", [])
      updated_collection = Map.put(collection, "requests", requests ++ [request_id])

      :ets.insert(@table_name, {collection_id, updated_collection})
      {:ok, updated_collection}
    end
  end

  @doc """
  Obtiene todas las colecciones.
  """
  def list_collections do
    @table_name
    |> :ets.tab2list()
    |> Enum.filter(fn {_, item} -> Map.has_key?(item, "requests") end)
    |> Enum.map(fn {_, collection} -> collection end)
  end
end
