defmodule CuzCoreConnectWeb.Datatable.Table do
  use Phoenix.Component
  # alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns = assign(assigns, :has_actions?, not Enum.empty?(assigns.action))

    ~H"""
    <div
      class="bg-white rounded-t-md overflow-hidden max-w-screen-0.5"
      id="table-container"
    >
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 table">
          <thead class="bg-gradient-to-r from-[#1e2a4a] to-[#2d3c61]">
            <tr class="table-row">
              <th
                :for={col <- @col}
                class="px-3 py-3 text-left text-xs font-medium text-white uppercase tracking-wider whitespace-nowrap"
              >
                {col[:label]}
              </th>

              <%= if @has_actions? do %>
                <th class="px-3 py-3 text-left text-xs font-medium text-white uppercase tracking-wider whitespace-nowrap">
                  Actions
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= if Enum.empty?(@rows) do %>
              <tr>
                <td
                  colspan={length(@col) + if(@has_actions?, do: 1, else: 0)}
                  class="px-3 py-6"
                >
                  <div class="bg-gray-50 border-2 border-dashed rouborder-gray-300 p-8 text-center">
                    <h3 class="text-lg font-medium text-gray-700 mb-1">
                      No data available
                    </h3>

                    <p class="text-sm text-gray-400 mb-4">
                      No records are available, or the applied filters returned no results.
                    </p>
                  </div>
                </td>
              </tr>
            <% else %>
              <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="table-row">
                <td
                  :for={{col, _i} <- Enum.with_index(@col)}
                  phx-click={@row_click && @row_click.(row)}
                  class={["px-3 py-3 whitespace-nowrap", @row_click && "hover:cursor-pointer"]}
                >
                  <div>{render_slot(col, @row_item.(row))}</div>
                </td>

                <%= if @has_actions? do %>
                  <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <div class="relative">
                      {render_slot(@action, row)}
                    </div>
                  </td>
                  <%!-- <td class="px-3 py-3 whitespace-nowrap">
                  <div class="relative">
                    <button
                      id={"dropdropdowndown-trigger-#{(@row_id && @row_id.(row)) || row.id}"}
                      type="button"
                      phx-click={
                        JS.dispatch("toggle-dropdown",
                          detail: %{id: (@row_id && @row_id.(row)) || row.id}
                        )
                      }
                      class="bg-[#0f172a] hover:bg-amber-500 text-white px-2 py-1 rounded-md text-sm font-medium transition duration-150 ease-in-out"
                    >
                      Options
                    </button>
                    <div
                      id={"dropdown-menu-#{@row_id && @row_id.(row) || row.id}"}
                      class="hidden bg-white rounded-md shadow-lg"
                    >
                      <%= render_slot(@action, @row_item.(row)) %>
                    </div>
                  </div>
                </td> --%>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
