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
    pipe_through [:browser]
    live_session :current_user,
      on_mount: [{CuzCoreConnectWeb.Plugs.UserAuth, :mount_current_scope}] do
      live "/users/log-in", UserLive.Login, :new

      scope "/" do
        pipe_through [:redirect_if_user_is_authenticated]

        live "/", LandingPageLive
        live "/learn-more", UserLive.LearnMore
        live "/student/registration", Student.Registration.RegistrationLive
        live "/registration/tracking", Student.Tracking.Index, :index
        live "/registration/tracking/:tracking_number", Student.Tracking.Index, :show

        live "/users/register", UserLive.Registration, :new
        live "/users/log-in/:token", UserLive.Confirmation, :new
      end
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
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
    pipe_through [:browser]

    live_session :require_admin_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_admin_role}
      ] do
      scope "/admin" do

        live "/dashboard", AdminLiveIndex, :index
        scope "/users" do
          live "/", Backend.UserManagement.Index, :index
          live "/new", Backend.UserManagement.Index, :new
          live "/:id/edit", Backend.UserManagement.Index, :edit
        end
      end
    end

    live_session :require_academics_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_academics_role}
      ] do
      scope "/academics" do
        live "/dashboard", StudentLive.Dashboard.Index, :index
      end
    end

    live_session :require_finance_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_finance_role}
      ] do
      scope "/finance" do
        live "/dashboard", StudentLive.Dashboard.Index, :index
      end
    end

    live_session :require_hod_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_hod_role}
      ] do
      scope "/hod" do
        live "/dashboard", StudentLive.Dashboard.Index, :index
      end
    end

    live_session :require_retention_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_retention_role}
      ] do
      scope "/retention" do
        live "/dashboard", StudentLive.Dashboard.Index, :index
      end
    end

    live_session :require_student_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_student_role}
      ] do
      scope "/student" do
        live "/dashboard", StudentLive.Dashboard.Index, :index
      end
    end

    live_session :require_authenticated_user,
      on_mount: [{CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end
end
