defmodule CuzCoreConnect.Pages.PageSeeds do
  @moduledoc """
  Seeds for the `Page` schema.
  """

  alias CuzCoreConnect.Pages.Page
  alias CuzCoreConnect.Repo

  # def plant do
  #   [
  #     %Page{name: "transactions"},
  #     %Page{name: "merchant profiles"},
  #     %Page{name: "payment links"},
  #     %Page{name: "accounts management"},
  #     %Page{name: "reports transactions"},
  #     %Page{name: "reports analytics"},
  #     %Page{name: "api credentials"},
  #     %Page{name: "api webhooks"},
  #     %Page{name: "api docs"},
  #     %Page{name: "test number selection"},
  #     %Page{name: "settings business"},
  #     %Page{name: "settings payments"},
  #     %Page{name: "settings notifications"},
  #   ]
  #   |> Enum.each(fn page ->
  #     Repo.insert!(page)
  #   end)
  # end

  def plant do
    Repo.delete_all(Page)

    (merchant_pages() ++ admin_pages())
    # admin_pages()
    |> Enum.each(fn attrs ->
      case Repo.get_by(Page,
             name: attrs.name,
             description: attrs.description,
             is_admin: attrs.is_admin
           ) do
        nil ->
          %Page{}
          |> Page.changeset(attrs)
          |> Repo.insert!()

          IO.puts("✓ Inserted page: #{attrs.name}")

        existing ->
          existing
          |> Page.changeset(attrs)
          |> Repo.update!()

          IO.puts("↺ Updated page: #{attrs.name}")
      end
    end)
  end

  defp merchant_pages do
    [
      %{
        name: "dashboard",
        description: "Merchant main dashboard",
        is_admin: false,
        paths: [
          "/merchant/dashboard"
        ]
      },
      %{
        name: "merchant_profiles",
        description: "Merchant profiles management",
        is_admin: false,
        paths: [
          "/merchant/profiles",
          "/merchant/profiles/new",
          "/merchant/profiles/:id",
          "/merchant/profiles/:id/edit",
          "/merchant/profiles/:id/documents"
        ]
      },
      %{
        name: "payment_links",
        description: "Payment links management",
        is_admin: false,
        paths: [
          "/merchant/payment-links"
        ]
      },
      %{
        name: "transactions_reports",
        description: "Transaction reports",
        is_admin: false,
        paths: [
          "/merchant/reports/transactions"
        ]
      },
      %{
        name: "analytics_reports",
        description: "Analytics reports",
        is_admin: false,
        paths: [
          "/merchant/reports/analytics"
        ]
      },
      %{
        name: "accounts_management",
        description: "User accounts management",
        is_admin: false,
        paths: [
          "/merchant/security/accounts-management"
        ]
      },
      %{
        name: "roles_and_permissions",
        description: "Roles and permissions management",
        is_admin: false,
        paths: [
          "/merchant/security/roles-permissions"
        ]
      },
      %{
        name: "webhooks",
        description: "Webhook integrations",
        is_admin: false,
        paths: [
          "/merchant/api/webhooks"
        ]
      },
      %{
        name: "documentations",
        description: "API documentation",
        is_admin: false,
        paths: [
          "/merchant/api/docs"
        ]
      },
      %{
        name: "test_numbers",
        description: "Phone simulator test numbers",
        is_admin: false,
        paths: [
          "/merchant/test-numbers",
          "/merchant/test-numbers/:id"
        ]
      },
      %{
        name: "business_settings",
        description: "Business information settings",
        is_admin: false,
        paths: [
          "/merchant/settings/business"
        ]
      },
      %{
        name: "payments_settings",
        description: "Payment method settings",
        is_admin: false,
        paths: [
          "/merchant/settings/payments"
        ]
      },
      %{
        name: "notifications_settings",
        description: "Notification preferences",
        is_admin: false,
        paths: [
          "/merchant/settings/notifications"
        ]
      }
    ]
  end

  defp admin_pages do
    [
      %{
        name: "merchant_profiles",
        description: "Admin merchant management",
        is_admin: true,
        paths: [
          "/admin/merchants",
          "/admin/merchants/new",
          "/admin/merchants/:id",
          "/admin/merchants/:id/edit",
          "/admin/merchants/:id/settings",
          "/admin/merchants/:id/analytics",
          "/admin/merchants/:id/settlements",
          "/admin/merchants/:merchant_id/settlements/:id"
        ]
      },
      %{
        name: "merchant_review",
        actions: [
          "manager_approve",
          "compliance_approve",
          "security_approve",
          "view",
          "create",
          "edit",
          "export",
          "delete"
        ],
        description: "Merchant KYC review",
        is_admin: true,
        paths: [
          "/admin/merchant-review",
          "/admin/merchant-review/:id"
        ]
      },
      %{
        name: "settlements",
        description: "Settlements management",
        is_admin: true,
        paths: [
          "/admin/settlements"
        ]
      },
      %{
        name: "transactions_reports",
        description: "Transaction reports",
        is_admin: true,
        paths: [
          "/admin/reports/transactions"
        ]
      },
      %{
        name: "analytics_reports",
        description: "Analytics reports",
        is_admin: true,
        paths: [
          "/admin/reports/analytics"
        ]
      },
      %{
        name: "session_logs",
        description: "User session logs",
        is_admin: true,
        paths: [
          "/admin/logs/session",
          "/admin/logs/session/:id"
        ]
      },
      %{
        name: "access_logs",
        description: "Access logs",
        is_admin: true,
        paths: [
          "/admin/logs/access",
          "/admin/logs/access/:id"
        ]
      },
      %{
        name: "api_logs",
        description: "API request logs",
        is_admin: true,
        paths: [
          "/admin/logs/api"
        ]
      },
      %{
        name: "system_logs",
        description: "System logs",
        is_admin: true,
        paths: [
          "/admin/logs/dashboard"
        ]
      },
      %{
        name: "payment_configs_mtn",
        description: "MTN payment configuration",
        is_admin: true,
        paths: [
          "/admin/payment-configs/mtn"
        ]
      },
      %{
        name: "payment_configs_airtel",
        description: "Airtel payment configuration",
        is_admin: true,
        paths: [
          "/admin/payment-configs/airtel"
        ]
      },
      %{
        name: "payment_configs_zamtel",
        description: "Zamtel payment configuration",
        is_admin: true,
        paths: [
          "/admin/payment-configs/zamtel"
        ]
      },
      %{
        name: "payment_configs_card",
        description: "Card payment configuration",
        is_admin: true,
        paths: [
          "/admin/payment-configs/card"
        ]
      },
      %{
        name: "payment_configs_bank",
        description: "Bank payment configuration",
        is_admin: true,
        paths: [
          "/admin/payment-configs/bank"
        ]
      },
      %{
        name: "woocommerce_documentation",
        description: "WooCommerce documentation management",
        is_admin: true,
        paths: [
          "/admin/woocommerce/documentation",
          "/admin/woocommerce/documentation/new",
          "/admin/woocommerce/documentation/:id/edit"
        ]
      },
      %{
        name: "woocommerce_plugins",
        description: "WooCommerce plugin management",
        is_admin: true,
        paths: [
          "/admin/woocommerce/plugins",
          "/admin/woocommerce/plugins/new",
          "/admin/woocommerce/plugins/:id/edit"
        ]
      },
      %{
        name: "api_management",
        description: "CuzCoreConnect API documentation management",
        is_admin: true,
        paths: [
          "/admin/api/documentation",
          "/admin/api/documentation/new",
          "/admin/api/documentation/:id/edit"
        ]
      },
      %{
        name: "internal_accounts_management",
        description: "Admin/Internal user accounts management",
        is_admin: true,
        paths: [
          "/admin/accounts-management/internal"
        ]
      },
      %{
        name: "external_accounts_management",
        description: "External user accounts management",
        is_admin: true,
        paths: [
          "/admin/accounts-management/external"
        ]
      },
      %{
        name: "roles_and_permissions",
        description: "Admin roles and permissions",
        is_admin: true,
        paths: [
          "/admin/security/roles-permissions"
        ]
      },
      %{
        name: "audits",
        description: "System audit logs",
        is_admin: true,
        paths: [
          "/admin/security/audit"
        ]
      },
      %{
        name: "system_settings",
        description: "General system settings",
        is_admin: true,
        paths: [
          "/admin/settings/system"
        ]
      },
      %{
        name: "merchant_profile_types",
        description: "Merchant profile type settings",
        is_admin: true,
        paths: [
          "/admin/profile-types",
          "/admin/profile-types/new",
          "/admin/profile-types/:id",
          "/admin/profile-types/:id/edit"
        ]
      },
      %{
        name: "settlements_work_flows",
        description: "Settlement workflow configuration",
        is_admin: true,
        paths: [
          "/admin/settings/settlements-work-flows"
        ]
      },
      %{
        name: "test_numbers",
        description: "Phone simulator test numbers",
        is_admin: true,
        paths: [
          "/admin/test-numbers"
        ]
      }
    ]
  end
end
