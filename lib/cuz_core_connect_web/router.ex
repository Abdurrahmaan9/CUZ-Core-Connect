defmodule CuzCoreConnectWeb.Router do
  use CuzCoreConnectWeb, :router

  import CuzCoreConnectWeb.Plugs.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CuzCoreConnectWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CuzCoreConnectWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/get-started", GetStartedLive
    live "/Student/registration", Student.Registration.RegistrationLive
    live "/registration/tracking", Student.Tracking.Index, :index
    live "/registration/tracking/:tracking_number", Student.Tracking.Index, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", CuzCoreConnectWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:cuz_core_connect, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CuzCoreConnectWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", CuzCoreConnectWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      scope "/students" do
        live "/pending", Academics.Students.Index, :index
      end
    end

    live_session :require_admin_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.AdminAuth, :ensure_admin}
      ] do
      scope "/Admin" do
        live "/Dashboard", Admin.Index, :index

        scope "/users" do
          live "/", Backend.UserMgt.Index, :index
          live "/new", Backend.UserMgt.Index, :new
          live "/:id/edit", Backend.UserMgt.Index, :edit
        end
      end
    end

    live_session :require_academics_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_academics_role}
      ] do
      scope "/Academics" do
        live "/Dashboard", SysUser.Dashboard.Index, :index
      end
    end

    live_session :require_finance_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_finance_role}
      ] do
      scope "/Finance" do
        live "/Dashboard", SysUser.Dashboard.Index, :index
      end
    end

    live_session :require_hod_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_hod_role}
      ] do
      scope "/HOD" do
        live "/Dashboard", SysUser.Dashboard.Index, :index
      end
    end

    live_session :require_retention_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_retention_role}
      ] do
      scope "/Retention" do
        live "/Dashboard", SysUser.Dashboard.Index, :index
      end
    end

    live_session :require_student_user,
      on_mount: [{CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated}] do
      scope "/Student" do
        live "/Dashboard", SysUser.Dashboard.Index, :index
      end
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", CuzCoreConnectWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{CuzCoreConnectWeb.Plugs.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
