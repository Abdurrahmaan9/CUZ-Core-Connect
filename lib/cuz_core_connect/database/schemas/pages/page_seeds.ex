defmodule CuzCoreConnect.Pages.PageSeeds do
  alias CuzCoreConnect.Pages.Page
  alias CuzCoreConnect.Repo

  @all_actions ~w(view create edit delete)

  def plant do
    Repo.delete_all(Page)

    all_pages()
    |> Enum.each(fn attrs ->
      case Repo.get_by(Page, name: attrs.name, role: attrs.role) do
        nil ->
          %Page{} |> Page.changeset(attrs) |> Repo.insert!()
          IO.puts("✓ Inserted [#{attrs.role}] #{attrs.name}")

        existing ->
          existing |> Page.changeset(attrs) |> Repo.update!()
          IO.puts("↺ Updated  [#{attrs.role}] #{attrs.name}")
      end
    end)
  end

  defp all_pages do
    admin_pages() ++
      academics_pages() ++
      finance_pages() ++
      hod_pages() ++
      retention_pages() ++
      student_pages()
  end

  # ── Admin ─────────────────────────────────────────────────────────────────
  # Admin gets ALL routes. No sidebar restriction — they see everything.

  defp admin_pages do
    [
      %{
        name: "admin_dashboard",
        description: "Admin main dashboard",
        role: "admin",
        actions: @all_actions,
        paths: ["/admin/dashboard"]
      },
      %{
        name: "student_registrations",
        description: "View and manage all student registrations",
        role: "admin",
        actions: @all_actions,
        paths: [
          "/admin/student",
          "/admin/student/pending",
          "/admin/student/registered"
        ]
      },
      %{
        name: "programmes",
        description: "Academic programme management",
        role: "admin",
        actions: @all_actions,
        paths: [
          "/admin/programmes",
          "/admin/programmes/new",
          "/admin/programmes/:id/edit"
        ]
      },
      %{
        name: "courses",
        description: "Course management",
        role: "admin",
        actions: @all_actions,
        paths: [
          "/admin/courses",
          "/admin/courses/new",
          "/admin/courses/:id/edit"
        ]
      },
      %{
        name: "reports_attendance",
        description: "Attendance reports",
        role: "admin",
        actions: ~w(view export),
        paths: ["/admin/reports/attendance"]
      },
      %{
        name: "reports_performance",
        description: "Performance analytics",
        role: "admin",
        actions: ~w(view export),
        paths: ["/admin/reports/performance"]
      },
      %{
        name: "messages",
        description: "Messaging",
        role: "admin",
        actions: ~w(view create delete),
        paths: ["/admin/messages"]
      },
      %{
        name: "announcements",
        description: "Announcements",
        role: "admin",
        actions: ~w(view create edit delete),
        paths: ["/admin/announcements"]
      },
      %{
        name: "internal_accounts",
        description: "Internal user account management",
        role: "admin",
        actions: @all_actions,
        paths: [
          "/admin/user-accounts/internal",
          "/admin/user-accounts/internal/new",
          "/admin/user-accounts/internal/:id/edit"
        ]
      },
      %{
        name: "external_accounts",
        description: "External user account management",
        role: "admin",
        actions: @all_actions,
        paths: [
          "/admin/user-accounts/external",
          "/admin/user-accounts/external/new",
          "/admin/user-accounts/external/:id/edit"
        ]
      },
      %{
        name: "registration_workflows",
        description: "Registration workflow configuration",
        role: "admin",
        actions: @all_actions,
        paths: [
          "/admin/workflows/registration",
          "/admin/workflows/registration/:id/edit"
        ]
      }
    ]
  end

  # ── Academics ─────────────────────────────────────────────────────────────

  defp academics_pages do
    [
      %{
        name: "academics_dashboard",
        description: "Academics main dashboard",
        role: "academics",
        actions: ~w(view),
        paths: ["/academics/dashboard"]
      },
      %{
        name: "academics_pending_review",
        description: "Registrations pending academic review",
        role: "academics",
        actions: ~w(view create edit),
        paths: ["/academics/dashboard?tab=pending"]
      },
      %{
        name: "academics_approved",
        description: "Academically approved registrations",
        role: "academics",
        actions: ~w(view export),
        paths: ["/academics/dashboard?tab=approved"]
      }
    ]
  end

  # ── Finance ───────────────────────────────────────────────────────────────

  defp finance_pages do
    [
      %{
        name: "finance_dashboard",
        description: "Finance main dashboard",
        role: "finance",
        actions: ~w(view),
        paths: ["/finance/dashboard"]
      },
      %{
        name: "finance_pending_payments",
        description: "Payments pending verification",
        role: "finance",
        actions: ~w(view create edit),
        paths: ["/finance/dashboard?tab=pending"]
      },
      %{
        name: "finance_verified",
        description: "Verified payments",
        role: "finance",
        actions: ~w(view export),
        paths: ["/finance/dashboard?tab=approved"]
      }
    ]
  end

  # ── HOD ───────────────────────────────────────────────────────────────────

  defp hod_pages do
    [
      %{
        name: "hod_dashboard",
        description: "HOD main dashboard",
        role: "hod",
        actions: ~w(view),
        paths: ["/hod/dashboard"]
      },
      %{
        name: "hod_pending_review",
        description: "Registrations pending HOD approval",
        role: "hod",
        actions: ~w(view create edit),
        paths: ["/hod/dashboard?tab=pending"]
      },
      %{
        name: "hod_approved",
        description: "HOD approved registrations",
        role: "hod",
        actions: ~w(view export),
        paths: ["/hod/dashboard?tab=approved"]
      }
    ]
  end

  # ── Retention ─────────────────────────────────────────────────────────────

  defp retention_pages do
    [
      %{
        name: "retention_dashboard",
        description: "Retention main dashboard",
        role: "retention",
        actions: ~w(view),
        paths: ["/retention/dashboard"]
      },
      %{
        name: "retention_final_review",
        description: "Final retention review queue",
        role: "retention",
        actions: ~w(view create edit),
        paths: ["/retention/dashboard?tab=pending"]
      },
      %{
        name: "retention_completed",
        description: "Completed registrations",
        role: "retention",
        actions: ~w(view export),
        paths: ["/retention/dashboard?tab=approved"]
      }
    ]
  end

  # ── Student ───────────────────────────────────────────────────────────────

  defp student_pages do
    [
      %{
        name: "student_dashboard",
        description: "Student main dashboard",
        role: "student",
        actions: ~w(view),
        paths: ["/student/dashboard"]
      },
      %{
        name: "student_my_registrations",
        description: "View my registrations",
        role: "student",
        actions: ~w(view),
        paths: ["/student/dashboard?tab=my_registrations"]
      },
      %{
        name: "student_new_registration",
        description: "Submit a new registration",
        role: "student",
        actions: ~w(view create),
        paths: [
          "/student/dashboard?tab=new_registration",
          "/student/registrations/new"
        ]
      },
      %{
        name: "student_registration_tracking",
        description: "Track registration by tracking number",
        role: "student",
        actions: ~w(view),
        paths: [
          "/registration/tracking",
          "/registration/tracking/:tracking_number"
        ]
      }
    ]
  end
end
