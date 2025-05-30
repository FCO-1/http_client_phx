defmodule HttpClientPhx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      HttpClientPhx.Repo,
      # Start the Telemetry supervisor
      HttpClientPhxWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HttpClientPhx.PubSub},
      # Start the Endpoint (http/https)
      HttpClientPhxWeb.Endpoint
      # Start a worker by calling: HttpClientPhx.Worker.start_link(arg)
      # {HttpClientPhx.Worker, arg}
       # Inicializamos la tabla ETS para las peticiones

      ]
      HttpClientPhx.Requests.init()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HttpClientPhx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HttpClientPhxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
