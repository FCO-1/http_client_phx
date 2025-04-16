defmodule HttpClientPhx.Repo do
  use Ecto.Repo,
    otp_app: :http_client_phx,
    adapter: Ecto.Adapters.Postgres
end
