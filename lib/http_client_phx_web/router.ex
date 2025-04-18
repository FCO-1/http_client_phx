defmodule HttpClientPhxWeb.Router do
  use HttpClientPhxWeb, :router

  # Define un pipeline llamado :browser que se utiliza para manejar solicitudes
  # HTML. Incluye plugs para aceptar solicitudes HTML, manejar sesiones,
  # mostrar mensajes flash en vivo, establecer un diseño raíz, proteger contra
  # ataques CSRF y configurar encabezados de seguridad.
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HttpClientPhxWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # Define un pipeline llamado :api que se utiliza para manejar solicitudes JSON.
  # Este pipeline es útil para construir APIs.
  pipeline :api do
    plug :accepts, ["json"]
  end

  # Define un scope para las rutas principales de la aplicación.
  # Usa el pipeline :browser para manejar estas rutas.
  scope "/", HttpClientPhxWeb do
    pipe_through :browser

    # Define una ruta GET para la raíz del sitio que apunta al controlador PageController
    # y a la acción :index.
    get "/", PageController, :index

    # Define una ruta para manejar LiveViews en "/request", apuntando al módulo
    # RequestLive.Index y a la acción :index.
    live "/request", RequestLive.Index, :index
  end

  # Sección comentada para definir un scope personalizado para APIs.
  # Puedes descomentar y personalizar esta sección si necesitas manejar rutas de API.
  # scope "/api", HttpClientPhxWeb do
  #   pipe_through :api
  # end

  # Habilita el LiveDashboard solo en entornos de desarrollo y prueba.
  # El LiveDashboard proporciona métricas y herramientas de depuración para Phoenix.
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      # Define una ruta para el LiveDashboard en "/dashboard".
      live_dashboard "/dashboard", metrics: HttpClientPhxWeb.Telemetry
    end
  end

  # Habilita la vista previa del buzón de Swoosh en desarrollo.
  # Esto permite ver los correos electrónicos enviados por la aplicación en un navegador.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      # Define una ruta para la vista previa del buzón en "/dev/mailbox".
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
