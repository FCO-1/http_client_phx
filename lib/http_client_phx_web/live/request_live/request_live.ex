defmodule HttpClientPhxWeb.RequestLive do
  use HttpClientPhxWeb, :live_view

  alias HttpClientPhx.HttpClient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:method, "GET")
     |> assign(:url, "")
     |> assign(:headers, [%{key: "", value: ""}])
     |> assign(:body, "")
     |> assign(:response, nil)
     |> assign(:loading, false)
     |> assign(:show_json_editor, false)
     |> assign(:saved_requests, HttpClientPhx.Requests.list_requests())
     |> assign(:collections, HttpClientPhx.Requests.list_collections())}
  end



  @impl true
  def handle_event("change-method", %{"method" => method}, socket) do
    {:noreply, assign(socket, :method, method)}
  end

  @impl true
  def handle_event("change-url", %{"url" => url}, socket) do
    {:noreply, assign(socket, :url, url)}
  end

  @impl true
  def handle_event("add-header", _, socket) do
    headers = socket.assigns.headers ++ [%{key: "", value: ""}]
    {:noreply, assign(socket, :headers, headers)}
  end

  @impl true
  def handle_event("remove-header", %{"index" => index}, socket) do
    index = String.to_integer(index)
    headers = List.delete_at(socket.assigns.headers, index)
    {:noreply, assign(socket, :headers, headers)}
  end

  @impl true
  def handle_event("change-header", %{"index" => index, "key" => key, "value" => value}, socket) do
    index = String.to_integer(index)
    headers = List.update_at(socket.assigns.headers, index, fn _ -> %{key: key, value: value} end)
    {:noreply, assign(socket, :headers, headers)}
  end

  @impl true
  def handle_event("change-body", %{"body" => body}, socket) do
    {:noreply, assign(socket, :body, body)}
  end

  @impl true
  def handle_event("toggle-json-editor", _, socket) do
    {:noreply, assign(socket, :show_json_editor, !socket.assigns.show_json_editor)}
  end

  @impl true
  def handle_event("send-request", _, socket) do
    url = socket.assigns.url
    method = socket.assigns.method |> String.downcase() |> String.to_atom()

    headers =
      socket.assigns.headers
      |> Enum.filter(fn h -> h.key != "" end)
      |> Enum.into(%{}, fn h -> {h.key, h.value} end)

    body =
      case socket.assigns.body do
        "" -> nil
        body -> parse_body(body, headers)
      end

    {:noreply, assign(socket, :loading, true)}

    Task.async(fn ->
      HttpClient.request(method, url, headers, body)
    end)

    {:noreply, assign(socket, :loading, true)}
  end

  @impl true
  def handle_info({ref, result}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:response, result)}
  end

  @impl true
  def handle_event("save-request", _, socket) do
    attrs = %{
      "name" => "Petición #{:os.system_time(:millisecond)}",
      "method" => socket.assigns.method,
      "url" => socket.assigns.url,
      "headers" => socket.assigns.headers,
      "body" => socket.assigns.body
    }

    {:ok, _request} = HttpClientPhx.Requests.create_request(attrs)

    {:noreply,
     socket
     |> assign(:saved_requests, HttpClientPhx.Requests.list_requests())
     |> put_flash(:info, "Petición guardada correctamente")}
  end

  @impl true
  def handle_event("load-request", %{"id" => id}, socket) do
    {:ok, request} = HttpClientPhx.Requests.get_request(id)

    {:noreply,
     socket
     |> assign(:method, request["method"])
     |> assign(:url, request["url"])
     |> assign(:headers, request["headers"])
     |> assign(:body, request["body"])}
  end

  @impl true
  def handle_event("delete-request", %{"id" => id}, socket) do
    :ok = HttpClientPhx.Requests.delete_request(id)

    {:noreply,
     socket
     |> assign(:saved_requests, HttpClientPhx.Requests.list_requests())
     |> put_flash(:info, "Petición eliminada correctamente")}
  end

  @impl true
  def handle_event("create-collection", %{"name" => name}, socket) do
    {:ok, _collection} = HttpClientPhx.Requests.create_collection(%{"name" => name})

    {:noreply,
     socket
     |> assign(:collections, HttpClientPhx.Requests.list_collections())
     |> put_flash(:info, "Colección creada correctamente")}
  end

  defp parse_body(body, headers) do
    content_type = Map.get(headers, "Content-Type", "")

    cond do
      String.contains?(content_type, "application/json") ->
        case Jason.decode(body) do
          {:ok, decoded} -> decoded
          _ -> body
        end

      true ->
        body
    end
  end

  defp format_response_body({:ok, %{body: body, headers: headers}}) do
    content_type =
      headers
      |> Enum.find(fn {key, _} -> String.downcase(key) == "content-type" end)
      |> case do
        {_, value} -> value
        _ -> ""
      end

    cond do
      String.contains?(content_type, "application/json") ->
        case Jason.decode(body) do
          {:ok, decoded} -> Jason.encode!(decoded, pretty: true)
          _ -> body
        end

      true ->
        body
    end
  end

  defp format_response_body({:error, %{reason: reason}}), do: "Error: #{inspect(reason)}"
  defp format_response_body(_), do: ""

  defp get_response_status({:ok, %{status_code: status_code}}), do: status_code
  defp get_response_status(_), do: nil

  defp get_response_headers({:ok, %{headers: headers}}), do: headers
  defp get_response_headers(_), do: []
end
