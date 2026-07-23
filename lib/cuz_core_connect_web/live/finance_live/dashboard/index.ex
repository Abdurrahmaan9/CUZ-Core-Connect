defmodule CuzCoreConnectWeb.FinanceLive.Dashboard.Index do
  use CuzCoreConnectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: CuzCoreConnect.Registrations.subscribe()

    {:ok,
     socket
     |> assign(:page_title, "Finance Dashboard")
     |> assign(:current_page, :finance_dashboard)
     |> assign(:active_tab, "overview")
     |> assign(:live_tick, 0)}
  end

  @impl true
  def handle_info({:registration_updated, _registration}, socket) do
    # Bump a counter so child live_components receive updated assigns and
    # re-run their update/2 (re-fetching pending lists) without a full reload.
    {:noreply, assign(socket, :live_tick, System.unique_integer())}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _url, socket)
      when tab in ["overview", "pending", "approved"] do
        current_page =
          cond do
            tab == "overview" -> :finance_dashboard
            tab == "pending" -> :finance_pending_payments
            tab == "approved" -> :finance_verified
          end
    {:noreply,
      assign(socket, :active_tab, tab)
     |> assign(:current_page, current_page)
    }
  end

  def handle_params(_params, _url, socket),
    do: {:noreply, assign(socket, :active_tab, "overview")}

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/finance/dashboard?tab=#{tab}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.user
      flash={@flash}
      current_scope={@current_scope}
      page_title={@page_title}
      current_page={@current_page}
    >

      <div class="mx-auto px-4 sm:px-6 lg:px-8">
        <%= case @active_tab do %>
          <% "overview" -> %>
            <.live_component
              module={CuzCoreConnectWeb.FinanceLive.Dashboard.OverviewComponent}
              id="finance-overview"
              current_scope={@current_scope}
              live_tick={@live_tick}
            />
          <% "pending" -> %>
            <.live_component
              module={CuzCoreConnectWeb.FinanceLive.Dashboard.PendingPaymentsComponent}
              id="finance-pending"
              current_scope={@current_scope}
              live_tick={@live_tick}
            />
          <% "approved" -> %>
            <.live_component
              module={CuzCoreConnectWeb.FinanceLive.Dashboard.ApprovedComponent}
              id="finance-approved"
              current_scope={@current_scope}
              live_tick={@live_tick}
            />
          <% _ -> %>
            <p class="text-center text-base-content/50 py-12">Tab not found</p>
        <% end %>
      </div>
    </Layouts.user>
    """
  end
end
