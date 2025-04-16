defmodule HttpClientPhx.HttpClient do
  @moduledoc """
  Módulo para manejar peticiones HTTP.
  Funciona como capa de abstracción sobre HTTPoison para realizar peticiones
  y procesar las respuestas.
  """

  @doc """
  Realiza una petición HTTP con los parámetros dados.

  ## Parámetros

  * `method` - Método HTTP (:get, :post, :put, :delete, etc.)
  * `url` - URL a la que se enviará la petición
  * `headers` - Mapa de headers para la petición
  * `body` - Cuerpo de la petición (puede ser string, mapa, etc.)
  * `options` - Opciones adicionales para HTTPoison

  ## Ejemplos

      iex> HttpClientPhx.HttpClient.request(:get, "https://api.example.com", %{}, nil, [])
      {:ok, %{body: "...", headers: [...], status_code: 200}}
  """
  def request(method, url, headers \\ %{}, body \\ nil, options \\ []) do
    headers = prepare_headers(headers)
    body = prepare_body(body, headers)

    method
    |> HTTPoison.request(url, body, headers, options)
    |> handle_response()
  end

  @doc """
  Prepara los headers para la petición HTTP.
  Convierte un mapa de headers a una lista de tuplas.
  """
  def prepare_headers(headers) when is_map(headers) do
    Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)
  end

  def prepare_headers(headers) when is_list(headers), do: headers
  def prepare_headers(_), do: []

  @doc """
  Prepara el cuerpo de la petición según los headers.
  Si el Content-Type es application/json, convierte el body a JSON.
  """
  def prepare_body(nil, _), do: ""
  def prepare_body(body, headers) when is_map(body) or is_list(body) do
    content_type = get_content_type(headers)

    if String.contains?(content_type, "application/json") do
      Jason.encode!(body)
    else
      body
    end
  end
  def prepare_body(body, _), do: body

  @doc """
  Obtiene el Content-Type de los headers.
  """
  def get_content_type(headers) do
    headers
    |> Enum.find(fn {k, _} -> String.downcase(k) == "content-type" end)
    |> case do
      {_, v} -> v
      _ -> ""
    end
  end

  @doc """
  Procesa la respuesta de HTTPoison.
  """
  def handle_response({:ok, %HTTPoison.Response{} = response}) do
    {:ok, %{
      body: response.body,
      headers: response.headers,
      status_code: response.status_code
    }}
  end

  def handle_response({:error, %HTTPoison.Error{} = error}) do
    {:error, %{
      reason: error.reason
    }}
  end

  @doc """
  Helper para peticiones GET.
  """
  def get(url, headers \\ %{}, options \\ []) do
    request(:get, url, headers, nil, options)
  end

  @doc """
  Helper para peticiones POST.
  """
  def post(url, body, headers \\ %{}, options \\ []) do
    request(:post, url, headers, body, options)
  end

  @doc """
  Helper para peticiones PUT.
  """
  def put(url, body, headers \\ %{}, options \\ []) do
    request(:put, url, headers, body, options)
  end

  @doc """
  Helper para peticiones DELETE.
  """
  def delete(url, headers \\ %{}, options \\ []) do
    request(:delete, url, headers, nil, options)
  end

  @doc """
  Helper para peticiones PATCH.
  """
  def patch(url, body, headers \\ %{}, options \\ []) do
    request(:patch, url, headers, body, options)
  end
end
