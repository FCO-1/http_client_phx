defmodule HttpClientPhxWeb.PageController do
  use HttpClientPhxWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
