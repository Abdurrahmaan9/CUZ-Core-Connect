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
      # Magic-link confirmation must remain reachable even when the visitor is
      # already authenticated (e.g. clicking a confirmation link from another
      # session) - the LiveView itself renders a different UI for that case.
      live "/users/log-in/:token", UserLive.Confirmation, :new

      # Public tracking works with or without authentication.
      live "/registration/tracking", Student.Tracking.Index, :index
      live "/registration/tracking/:tracking_number", Student.Tracking.Index, :show

      scope "/" do
        pipe_through [:redirect_if_user_is_authenticated]

        live "/", LandingPageLive
        live "/learn-more", UserLive.LearnMore
        live "/student/registration", Student.Registration.RegistrationLive

        live "/users/register", UserLive.Registration, :new
      end
    end

    # Public proof of registration for approved tracking numbers.
    get "/registration/tracking/:tracking_number/proof", CertificateController, :show_by_tracking

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
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_admin_role},
        {CuzCoreConnectWeb.Hooks.Notifications, :default}
      ] do
      scope "/admin" do
        live "/dashboard", AdminLiveIndex, :index

        scope "/student" do
          live "/", Academics.Students
          live "/pending", Academics.Students.PendingRegistration, :index
          live "/registered", Academics.Students.Registered
        end

        scope "/programmes" do
          live "/", Admin.AcademicManagement.Programmes.Index, :index
          live "/new", Admin.AcademicManagement.Programmes.Index, :new
          live "/:id", Admin.AcademicManagement.Programmes.Index, :show
          live "/:id/edit", Admin.AcademicManagement.Programmes.Index, :edit
        end

        scope "/courses" do
          live "/", Admin.AcademicManagement.Courses.Index, :index
          live "/new", Admin.AcademicManagement.Courses.Index, :new
          live "/:id/edit", Admin.AcademicManagement.Courses.Index, :edit
        end

        scope "/reports" do
          live "/attendance", Admin.Reports.Attendance
          live "/performance", Admin.Reports.Performance
        end

        scope "/messages" do
          live "/", Admin.Messages
        end

        scope "/email-logs" do
          live "/", Admin.EmailLogs
        end

        scope "/announcements" do
          live "/", Admin.Announcements
        end

        scope "/user-accounts" do
          live "/internal", Admin.UserAccounts.Internal, :index

          live "/internal/new", Admin.UserAccounts.Internal, :new
          live "/internal/:id/edit", Admin.UserAccounts.Internal, :edit

          live "/external", Admin.UserAccounts.External, :index

          live "/external/new", Admin.UserAccounts.External, :new
          live "/external/:id/edit", Admin.UserAccounts.External, :edit
        end

        scope "/workflows" do
          live "/registration", Admin.RegistrationWorkflow
          live "/registration/:id/edit", Admin.RegistrationWorkflow, :edit
        end
      end
    end

    live_session :require_academics_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_academics_role},
        {CuzCoreConnectWeb.Hooks.Notifications, :default}
      ] do
      scope "/academics" do
        live "/dashboard", AcademicsLive.Dashboard.Index, :index
      end
    end

    live_session :require_finance_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_finance_role},
        {CuzCoreConnectWeb.Hooks.Notifications, :default}
      ] do
      scope "/finance" do
        live "/dashboard", FinanceLive.Dashboard.Index, :index
      end
    end

    live_session :require_hod_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_hod_role},
        {CuzCoreConnectWeb.Hooks.Notifications, :default}
      ] do
      scope "/hod" do
        live "/dashboard", HODLive.Dashboard.Index, :index
      end
    end

    live_session :require_retention_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_retention_role},
        {CuzCoreConnectWeb.Hooks.Notifications, :default}
      ] do
      scope "/retention" do
        live "/dashboard", RetentionLive.Dashboard.Index, :index
      end
    end

    live_session :require_student_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Plugs.UserAuth, :ensure_student_role},
        {CuzCoreConnectWeb.Hooks.Notifications, :default}
      ] do
      scope "/student" do
        live "/dashboard", StudentLive.Dashboard.Index, :index
        live "/registrations/new", Student.Registration.RegistrationLive

        # live "/pending", Academics.Students.Index, :index
      end
    end

    live_session :require_authenticated_user,
      on_mount: [
        {CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated},
        {CuzCoreConnectWeb.Hooks.Notifications, :default}
      ] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/users/notifications", UserLive.Notifications, :index
    end

    scope "/" do
      pipe_through [:require_authenticated_user]
      post "/users/update-password", UserSessionController, :update_password
    end

    get "/receipts/:id", ReceiptController, :show
    get "/registrations/:id/certificate", CertificateController, :show
  end
end
