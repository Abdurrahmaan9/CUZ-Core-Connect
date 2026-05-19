defmodule CuzCoreConnectWeb.Student.Tracking.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Registration

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_scope, nil)
     |> assign(:tracking_number, "")
     |> assign(:registration, nil)
     |> assign(:searched, false)
     |> assign(:show_mobile_menu, false)
     |> assign(:loading, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.unauth flash={@flash}>
      <:header>
        <CuzCoreConnectWeb.Navigations.Unauth.header show_mobile_menu={@show_mobile_menu} />
      </:header>
      <div class="max-w-4xl mx-auto py-8 px-4 sm:px-6">
        <div class="text-center mb-8">
          <h1 class="text-2xl sm:text-3xl font-bold text-base-content mb-2">Track Your Registration</h1>
          <p class="text-sm sm:text-base text-base-content/70">
            Enter your tracking number to check your registration status
          </p>
        </div>

        <div class="bg-base-100 rounded-2xl shadow-sm border border-base-200 p-4 sm:p-6 lg:p-8">
          <!-- Search Form -->
          <div class="mb-8">
            <form phx-submit="search_tracking" class="flex flex-col sm:flex-row gap-4">
              <div class="flex-1">
                <input
                  type="text"
                  name="tracking_number"
                  id="tracking_number"
                  value={@tracking_number}
                  placeholder="Enter tracking number (e.g., REG-17143584000-a1b2c3)"
                  class="w-full px-3 py-2 sm:px-4 sm:py-3 text-sm sm:text-lg border border-base-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary"
                  required
                />
              </div>
              <button
                type="submit"
                phx-disable-with="Searching..."
                class="w-full sm:w-auto px-4 py-2 sm:px-6 sm:py-3 bg-primary text-primary-content rounded-lg hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center justify-center"
              >
                <.icon name="hero-magnifying-glass" class="w-4 h-4 sm:w-5 sm:h-5 mr-2" /> Track
              </button>
            </form>
          </div>

    <!-- Loading State -->
          <%= if @loading do %>
            <div class="text-center py-8 sm:py-12">
              <div class="inline-block animate-spin rounded-full h-6 w-6 sm:h-8 sm:w-8 border-b-2 border-primary">
              </div>
              <p class="mt-4 text-sm sm:text-base text-base-content/70">Searching for your registration...</p>
            </div>
          <% end %>

    <!-- Registration Results -->
          <%= if @searched && !@loading do %>
            <%= if @registration do %>
              <div class="space-y-4 sm:space-y-6">
                <!-- Success Message -->
                <div class="bg-success/10 border border-success/20 rounded-lg p-3 sm:p-4">
                  <div class="flex items-center">
                    <.icon name="hero-check-circle" class="w-5 h-5 sm:w-6 sm:h-6 text-success mr-2 sm:mr-3" />
                    <div>
                      <h3 class="text-success font-semibold text-sm sm:text-base">Registration Found</h3>
                      <p class="text-success/80 text-xs sm:text-sm">Your registration details are shown below</p>
                    </div>
                  </div>
                </div>

    <!-- Registration Details -->
                <div class="space-y-4 sm:space-y-6">
                  <!-- Student ID -->
                  <%= if @registration.student_id do %>
                    <div class="bg-base-200 rounded-lg p-4 sm:p-6">
                      <h3 class="text-base sm:text-lg font-semibold text-base-content mb-3 sm:mb-4 flex items-center">
                        <.icon name="hero-identification" class="w-4 h-4 sm:w-5 sm:h-5 mr-2" /> Student Information
                      </h3>
                      <div>
                        <span class="text-xs sm:text-sm font-medium text-base-content/70">Student Number:</span>
                        <p class="text-base-content font-mono font-semibold text-base sm:text-lg break-all">
                          {@registration.student_id}
                        </p>
                      </div>
                    </div>
                  <% end %>

    <!-- Registration Status -->
                  <div class="bg-base-200 rounded-lg p-4 sm:p-6">
                    <h3 class="text-base sm:text-lg font-semibold text-base-content mb-3 sm:mb-4 flex items-center">
                      <.icon name="hero-clipboard-document-check" class="w-4 h-4 sm:w-5 sm:h-5 mr-2" />
                      Registration Status
                    </h3>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <span class="text-xs sm:text-sm font-medium text-base-content/70">Approval Status:</span>
                        <div class="mt-1">
                          <span class={[
                            "inline-flex items-center px-2 py-1 sm:px-3 sm:py-1 rounded-full text-xs sm:text-sm font-medium",
                            case @registration.approval_level do
                              "approved" -> "bg-success/20 text-success"
                              "pending" -> "bg-warning/20 text-warning"
                              "rejected" -> "bg-error/20 text-error"
                              _ -> "bg-base-300 text-base-content"
                            end
                          ]}>
                            <.icon
                              name={
                                case @registration.approval_level do
                                  "approved" -> "hero-check-circle"
                                  "pending" -> "hero-clock"
                                  "rejected" -> "hero-x-circle"
                                  _ -> "hero-question-mark-circle"
                                end
                              }
                              class="w-3 h-3 sm:w-4 sm:h-4 mr-1"
                            />
                            {String.capitalize(@registration.approval_level || "Unknown")}
                          </span>
                        </div>
                      </div>
                      <div>
                        <span class="text-xs sm:text-sm font-medium text-base-content/70">Payment Status:</span>
                        <div class="mt-1">
                          <span class={[
                            "inline-flex items-center px-2 py-1 sm:px-3 sm:py-1 rounded-full text-xs sm:text-sm font-medium",
                            case @registration.payment_status do
                              "verified" -> "bg-success/20 text-success"
                              "pending" -> "bg-warning/20 text-warning"
                              "rejected" -> "bg-error/20 text-error"
                              _ -> "bg-base-300 text-base-content"
                            end
                          ]}>
                            <.icon
                              name={
                                case @registration.payment_status do
                                  "verified" -> "hero-check-circle"
                                  "pending" -> "hero-clock"
                                  "rejected" -> "hero-x-circle"
                                  _ -> "hero-question-mark-circle"
                                end
                              }
                              class="w-3 h-3 sm:w-4 sm:h-4 mr-1"
                            />
                            {String.capitalize(@registration.payment_status || "Unknown")}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

    <!-- Program Details -->
                <%= if @registration.student_program_details do %>
                  <div class="bg-primary/10 rounded-lg p-4 sm:p-6">
                    <h3 class="text-base sm:text-lg font-semibold text-base-content mb-3 sm:mb-4 flex items-center">
                      <.icon name="hero-academic-cap" class="w-4 h-4 sm:w-5 sm:h-5 mr-2" /> Program Details
                    </h3>
                    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                      <div>
                        <span class="text-xs sm:text-sm font-medium text-base-content/70">Program:</span>
                        <p class="text-sm sm:text-base text-base-content font-medium break-words">
                          {@registration.student_program_details["program_name"]}
                        </p>
                      </div>
                      <div>
                        <span class="text-xs sm:text-sm font-medium text-base-content/70">Academic Year:</span>
                        <p class="text-sm sm:text-base text-base-content">
                          {@registration.student_program_details["academic_year"]}
                        </p>
                      </div>
                      <div>
                        <span class="text-xs sm:text-sm font-medium text-base-content/70">Semester:</span>
                        <p class="text-sm sm:text-base text-base-content">
                          {@registration.student_program_details["semester"]}
                        </p>
                      </div>
                    </div>
                  </div>
                <% end %>

    <!-- Courses -->
                <%= if @registration.student_courses && @registration.student_courses["selected_courses"] do %>
                  <div class="bg-secondary/10 rounded-lg p-4 sm:p-6">
                    <h3 class="text-base sm:text-lg font-semibold text-base-content mb-3 sm:mb-4 flex items-center">
                      <.icon name="hero-book-open" class="w-4 h-4 sm:w-5 sm:h-5 mr-2" /> Registered Courses
                    </h3>
                    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
                      <%= for course <- @registration.student_courses["selected_courses"] do %>
                        <div class="bg-base-100 rounded-lg p-3 sm:p-4 border border-secondary/20">
                          <div class="flex justify-between items-start mb-2">
                            <span class="font-mono text-xs sm:text-sm text-secondary font-semibold break-all">
                              {course["code"]}
                            </span>
                            <span class="text-xs sm:text-sm text-base-content/60 whitespace-nowrap">
                              {course["credit_hours"]} cr
                            </span>
                          </div>
                          <p class="text-xs sm:text-sm text-base-content font-medium break-words">{course["name"]}</p>
                        </div>
                      <% end %>
                    </div>
                    <div class="mt-4 pt-4 border-t border-secondary/20">
                      <div class="flex justify-between items-center">
                        <span class="text-xs sm:text-sm font-medium text-base-content/70">
                          Total Credit Hours:
                        </span>
                        <span class="text-base sm:text-lg font-bold text-secondary">
                          {@registration.student_courses["total_credit_hours"]}
                        </span>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% else %>
              <!-- Not Found Message -->
              <div class="text-center py-8 sm:py-12">
                <.icon name="hero-exclamation-triangle" class="w-12 h-12 sm:w-16 sm:h-16 text-error mx-auto mb-4" />
                <h3 class="text-lg sm:text-xl font-semibold text-base-content mb-2">Registration Not Found</h3>
                <p class="text-sm sm:text-base text-base-content/70 mb-6 px-4">
                  We couldn't find a registration with that tracking number. Please check the number and try again.
                </p>
                <div class="bg-base-200 rounded-lg p-3 sm:p-4 max-w-md mx-auto">
                  <h4 class="font-medium text-base-content mb-2 text-sm sm:text-base">Tips:</h4>
                  <ul class="text-xs sm:text-sm text-base-content/70 space-y-1 text-left">
                    <li>• Make sure you entered the complete tracking number</li>
                    <li>• Check for any typos or extra spaces</li>
                    <li>• The format should be: REG-1234567890-abc123</li>
                    <li>• Contact support if you continue to have issues</li>
                  </ul>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
      <:footer>
        <CuzCoreConnectWeb.Navigations.Unauth.footer />
      </:footer>
    </Layouts.unauth>
    """
  end

    @impl true
  def handle_params(%{"tracking_number" => tracking_number}, _url, socket) do
    if tracking_number && tracking_number != "" do
      search_registration(socket, String.trim(tracking_number))
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_params(%{}, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search_tracking", %{"tracking_number" => tracking_number}, socket) do
    tracking_number = String.trim(tracking_number)

    socket =
      socket
      |> assign(:tracking_number, tracking_number)
      |> assign(:loading, true)
      |> assign(:searched, false)
      |> assign(:registration, nil)

    search_registration(socket, tracking_number)
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end

  # Private helper functions
  defp search_registration(socket, tracking_number) do
    case Registration.get_registration_by_tracking_number(tracking_number) do
      nil ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:searched, true)
         |> assign(:registration, nil)}

      registration ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:searched, true)
         |> assign(:registration, registration)}
    end
  end
end
