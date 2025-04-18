defmodule HttpClientPhxWeb.RequestLive.Index do
    use HttpClientPhxWeb, :live_view

    #alias HttpClientPhx.HttpClient
    alias HttpClientPhx.Context.RequestsContext

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
       |> assign(:saved_requests, RequestsContext.list_requests())
       |> assign(:collections, RequestsContext.list_collections())
       |> assign(:request_id, nil)}
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
    def handle_event("change-header-key", %{"index" => index, "value" => value}, socket) do
      index = String.to_integer(index)
      headers = List.update_at(socket.assigns.headers, index, fn header -> %{key: value, value: header.value} end)
      {:noreply, assign(socket, :headers, headers)}
    end

    @impl true
    def handle_event("change-header-value", %{"index" => index, "value" => value}, socket) do
      index = String.to_integer(index)
      headers = List.update_at(socket.assigns.headers, index, fn header -> %{key: header.key, value: value} end)
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

      # Hacer la petición HTTP
      Task.async(fn ->
        result = HttpClient.request(method, url, headers, body)

        # Si tenemos una petición guardada, actualizar su respuesta
        if socket.assigns.request_id do
          case result do
            {:ok, %{body: response_body, headers: response_headers, status_code: status_code}} ->
              RequestsContext.update_request_response(
                socket.assigns.request_id,
                status_code,
                response_headers,
                response_body
              )
            _ ->
              # No hacer nada si hay un error
              nil
          end
        end

        result
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
        name: "Petición #{:os.system_time(:millisecond)}",
        method: socket.assigns.method,
        url: socket.assigns.url,
        headers: socket.assigns.headers,
        body: socket.assigns.body
      }

      case RequestsContext.create_request(attrs) do
        {:ok, request} ->
          {:noreply,
           socket
           |> assign(:saved_requests, RequestsContext.list_requests())
           |> assign(:request_id, request.id)
           |> put_flash(:info, "Petición guardada correctamente")}

        {:error, changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Error al guardar la petición: #{inspect(changeset.errors)}")}
      end
    end

    @impl true
    def handle_event("load-request", %{"id" => id}, socket) do
      case RequestsContext.get_request(id) do
        {:ok, request} ->
          {:noreply,
           socket
           |> assign(:method, request.method)
           |> assign(:url, request.url)
           |> assign(:headers, request.headers)
           |> assign(:body, request.body)
           |> assign(:request_id, request.id)}

        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "No se encontró la petición")}
      end
    end

    @impl true
    def handle_event("delete-request", %{"id" => id}, socket) do
      case RequestsContext.delete_request(id) do
        {:ok, _request} ->
          {:noreply,
           socket
           |> assign(:saved_requests, RequestsContext.list_requests())
           |> put_flash(:info, "Petición eliminada correctamente")}

        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "Error al eliminar la petición")}
      end
    end



    @impl true
    def handle_event("assign-to-collection", %{"request_id" => request_id, "value" => collection_id}, socket) do
      # Si el collection_id está en blanco, asignamos nil
      collection_id = if collection_id == "", do: nil, else: collection_id

      case RequestsContext.update_request(request_id, %{collection_id: collection_id}) do
        {:ok, _request} ->
          {:noreply,
           socket
           |> assign(:saved_requests, RequestsContext.list_requests())
           |> put_flash(:info, "Petición asignada a la colección correctamente")}

        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "Error al asignar la petición a la colección")}
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

    defp format_response_body({:error, %{reason: reason}}), do: "Error: #{inspect(reason)}"
    defp format_response_body(_), do: ""

    defp get_response_status({:ok, %{status_code: status_code}}), do: status_code
    defp get_response_status(_), do: nil

    defp get_response_headers({:ok, %{headers: headers}}), do: headers
    defp get_response_headers(_), do: []
  end
