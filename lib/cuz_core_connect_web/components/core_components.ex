defmodule CuzCoreConnectWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: CuzCoreConnectWeb.Gettext

  alias Phoenix.LiveView.JS

  alias CuzCoreConnectWeb.Utilities.Pagination
  alias CuzCoreConnectWeb.Utilities.Sorting

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns =
      assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-hook="AutoFade"
      data-fade-delay="100000"
      phx-click={hide(JS.push("lv:clear-flash", value: %{key: @kind}), "##{@id}")}
      role="alert"
      class="fixed top-21 left-1/2 z-[999] transition-all duration-500 ease-in-out"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "password"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">
          {@label}<span :if={Map.has_key?(@rest, :required) and @rest.required} class="text-red-500">*</span>
        </span>
        <div class="relative">
          <input
            type="password"
            name={@name}
            id={@id}
            value={Phoenix.HTML.Form.normalize_value(@type, @value)}
            class={[
              @class || "w-full input",
              @errors != [] && (@error_class || "input-error")
            ]}
            {@rest}
          />
          <button
            id={"#{@id}-password-toggle-button"}
            type="button"
            phx-hook="PasswordToggle"
            data-target={@id}
            class="absolute inset-y-0 right-2 px-3 flex items-center text-gray-400 hover:text-gray-600 focus:outline-none"
          >
            <%!-- show icon (eye) --%>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="show-icon hidden h-5 w-5 size-6"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z"
              />
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
              />
            </svg>
            <%!-- hide icon (eye-off) --%>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="hide-icon h-5 w-5 size-6"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M3.98 8.223A10.477 10.477 0 0 0 1.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.451 10.451 0 0 1 12 4.5c4.756 0 8.773 3.162 10.065 7.498a10.522 10.522 0 0 1-4.293 5.774M6.228 6.228 3 3m3.228 3.228 3.65 3.65m7.894 7.894L21 21m-3.228-3.228-3.65-3.65m0 0a3 3 0 1 0-4.243-4.243m4.242 4.242L9.88 9.88"
              />
            </svg>
          </button>
        </div>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
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
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a modern, aesthetic table with enhanced styling.

  ## Examples

      <.modern_table id="registrations" rows={@registrations} class="shadow-sm">
        <:col :let={registration} label="Student Details">
          <div class="text-sm font-medium text-gray-900">{registration.student_names}</div>
          <div class="text-sm text-gray-500">{registration.student_email}</div>
        </:col>
        <:col :let={registration} label="Program">{registration.program}</:col>
        <:action :let={registration}>
          <.link navigate={~p"/registrations/\#{registration.id}"} class="text-indigo-600 hover:text-indigo-900">
            View
          </.link>
        </:action>
      </.modern_table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :class, :any, default: nil, doc: "additional CSS classes for the table wrapper"
  attr :show_header, :boolean, default: true, doc: "whether to show the table header"
  attr :empty_state_title, :string, default: "No data available", doc: "title for empty state"

  attr :empty_state_description, :string,
    default: "There are no items to display.",
    doc: "description for empty state"

  attr :search_placeholder, :string,
    default: "Search",
    doc: "placeholder text for the table search input"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def modern_table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class={[
      "rounded-md border border-base-200 bg-base-100 px-6 py-5 shadow-sm",
      @class
    ]}>
      <%= if @show_header do %>
        <div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div class="flex w-full max-w-[214px] overflow-hidden rounded-md border border-base-300 bg-base-100 shadow-sm transition duration-150 focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/20">
            <span class="flex h-[34px] w-[30px] shrink-0 items-center justify-center bg-primary text-primary-content">
              <.icon name="hero-magnifying-glass" class="size-4" />
            </span>
            <input
              id={"#{@id}-search"}
              type="search"
              name="search"
              placeholder={@search_placeholder}
              class="h-[34px] min-w-0 flex-1 border-0 bg-base-100 px-2 text-xs text-base-content outline-none placeholder:text-base-content/50 focus:ring-0"
            />
          </div>

          <div class="flex flex-wrap items-center gap-2 lg:justify-end">
            <button
              type="button"
              id={"#{@id}-export"}
              class="inline-flex h-[30px] items-center rounded-md bg-primary px-3 text-[11px] font-bold tracking-wide text-primary-content transition duration-150 hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/20"
            >
              Export
            </button>
            <button
              type="button"
              id={"#{@id}-filter"}
              class="inline-flex h-[30px] items-center gap-1.5 rounded-md bg-primary px-3 text-[11px] font-bold tracking-wide text-primary-content transition duration-150 hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/20"
            >
              <.icon name="hero-funnel" class="size-3.5" /> Filter
            </button>
            <button
              type="button"
              id={"#{@id}-transactions-report"}
              class="inline-flex h-[30px] items-center gap-1.5 rounded-md bg-primary px-3 text-[11px] font-bold tracking-wide text-primary-content transition duration-150 hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/20"
            >
              <.icon name="hero-chart-bar-square" class="size-3.5" /> Transactions Report
            </button>
            <button
              type="button"
              id={"#{@id}-reload"}
              class="inline-flex h-[30px] items-center gap-1.5 rounded-md bg-primary px-3 text-[11px] font-bold tracking-wide text-primary-content transition duration-150 hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/20"
            >
              <.icon name="hero-arrow-path" class="size-3.5" /> Reload
            </button>
          </div>
        </div>
      <% end %>

      <%= if @rows == [] do %>
        <div class="rounded-md border border-dashed border-base-200 px-8 py-14 text-center">
          <div class="mb-5 inline-flex size-12 items-center justify-center rounded-full bg-base-200">
            <.icon name="hero-inbox" class="size-6 text-base-content/50" />
          </div>
          <h3 class="mb-2 text-sm font-semibold text-base-content">{@empty_state_title}</h3>
          <p class="mx-auto max-w-md text-xs text-base-content/70">{@empty_state_description}</p>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="min-w-full table-fixed border-separate border-spacing-0">
            <thead>
              <tr>
                <th
                  :for={col <- @col}
                  class={[
                    "bg-primary px-2 py-2 text-left text-[9px] font-medium uppercase leading-none tracking-wide text-primary-content first:rounded-l-md",
                    col[:class] || ""
                  ]}
                >
                  {col[:label]}
                </th>
                <th
                  :if={@action != []}
                  class="rounded-r-md bg-primary px-2 py-2 text-right text-[9px] font-medium uppercase leading-none tracking-wide text-primary-content"
                >
                </th>
              </tr>
            </thead>
            <tbody
              id={@id}
              phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}
            >
              <tr
                :for={row <- @rows}
                id={@row_id && @row_id.(row)}
                class="group transition duration-150 hover:bg-base-200"
              >
                <td
                  :for={col <- @col}
                  phx-click={@row_click && @row_click.(row)}
                  class={[
                    "px-2 py-4 align-top text-[10px] leading-5 text-base-content",
                    @row_click && "hover:cursor-pointer"
                  ]}
                >
                  {render_slot(col, @row_item.(row))}
                </td>
                <td :if={@action != []} class="px-0 py-3 text-right align-top">
                  <div class="flex items-center justify-end gap-2">
                    <%= for action <- @action do %>
                      <div>
                        {render_slot(action, @row_item.(row))}
                      </div>
                    <% end %>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="pt-3 text-[10px] text-base-content">
          Showing 1 to {modern_table_row_count(@rows)} of {modern_table_row_count(@rows)} entries
        </div>
      <% end %>
    </div>
    """
  end

  defp modern_table_row_count(%Phoenix.LiveView.LiveStream{}), do: 0
  defp modern_table_row_count(rows) when is_list(rows), do: length(rows)
  defp modern_table_row_count(_rows), do: 0

  @doc ~S"""
  Renders a table with generic styling and sorting functionality.

  ## Examples

      <.table id="users" rows={@users} filter_params={@filter_params}>
        <:col :let={user} label="id" filter_item="id">{user.id}</:col>
        <:col :let={user} label="username" filter_item="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :filter_params, :map, default: %{}
  attr :pagination, :map
  attr :selected_column, :string, default: "inserted_at"
  attr :list_of_operators, :list, default: []
  attr :operator, :string, default: ""
  attr :query_fields_list, :list, default: []
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :filter_url, :string, default: "#"
  attr :export_url, :string, default: "#"
  attr :show_filter, :boolean, default: false
  attr :show_export, :boolean, default: false

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :filter_item, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table_with_sorting(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="px-2 sm:px-0">
      <div class="p-2">
        <div class="overflow-x-auto overflow-y-hidden sm:rounded-lg">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="text-[12px] text-left leading-4 text-white">
              <tr class="bg-[#0c2f9d] text-left font-medium text-white uppercase tracking-wider sticky top-0">
                <th :for={col <- @col} class="p-2 pb-2 pr-3 font-normal whitespace-nowrap">
                  <div class="flex items-center gap-2">
                    <span class="sm:mr-auto xl:flex text-[11px]">{col[:label]}</span>
                    <a
                      :if={col[:filter_item]}
                      href={Sorting.table_link_encode_url(@filter_params, col[:filter_item])}
                      data-phx-link="redirect"
                      data-phx-link-state="push"
                      class="inline-flex items-center hover:text-gray-700 transition-colors duration-200"
                    >
                      {Phoenix.HTML.raw(icon_def(@filter_params, col[:filter_item], @selected_column))}
                    </a>
                  </div>
                </th>
                <th :if={@action != []} class="relative p-0 pb-2">
                  <span class="sr-only">{gettext("Actions")}</span>
                </th>
              </tr>
            </thead>
            <tbody
              id={@id}
              phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}
              class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-[12px] leading-4 text-zinc-700 bg-white"
            >
              <tr
                :for={row <- @rows}
                id={@row_id && @row_id.(row)}
                class="group hover:bg-gray-50 transition duration-150"
              >
                <td
                  :for={{col, i} <- Enum.with_index(@col)}
                  phx-click={@row_click && @row_click.(row)}
                  class={[
                    "relative px-1 py-1 text-[12px] text-gray-900 whitespace-nowrap",
                    @row_click && "hover:cursor-pointer"
                  ]}
                >
                  <div class="block py-1 pr-2">
                    <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-gray-50 sm:rounded-l-xl" />
                    <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                      {render_slot(col, @row_item.(row))}
                    </span>
                  </div>
                </td>
                <td :if={@action != []} class="relative w-12 p-0">
                  <div class="relative whitespace-nowrap text-left text-[12px] font-medium">
                    <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-gray-50 sm:rounded-r-xl" />
                    <span
                      :for={action <- @action}
                      class="relative ml-3 font-semibold leading-4 text-zinc-900 hover:text-zinc-700"
                    >
                      {render_slot(action, @row_item.(row))}
                    </span>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  # Navigation Link Component
  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :active, :boolean, default: false
  attr :label, :string, required: true

  def navigation_link(assigns) do
    ~H"""
    <div
      phx-click={JS.navigate(@href)}
      class={[
        "flex items-center px-1 py-3 text-sm font-medium rounded-r transition-all duration-200 group cursor-pointer",
        if(@active,
          do: "bg-primary/20 border-l-2 border-orange-500",
          else:
            "hover:bg-secondary/50 hover:border-l-2 hover:border-orange-500/50"
        )
      ]}
    >
      <.icon name={"hero-" <> @icon} class="w-5 h-5 mr-2" />
      <span>{@label}</span>
    </div>
    """
  end

  # Dropdown Menu Component
  attr :id, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  slot :inner_block, required: true

  def dropdown_menu(assigns) do
    ~H"""
    <div class="space-y-1">
      <button
        phx-click={toggle_dropdown("##{@id}")}
        class={[
          "w-full flex items-center justify-between px-1 py-3 text-sm font-medium rounded-md transition-all duration-200 group cursor-pointer ",
          if(@active,
            do: "bg-primary/20 border-l-2 border-orange-500",
            else:
              "hover:bg-secondary/50 hover:border-l-2 hover:border-orange-500/50"
          )
        ]}
      >
        <div class="flex items-center">
          <.icon name={"hero-" <> @icon} class="w-5 h-5 mr-2" />
          <span>{@label}</span>
        </div>
        <svg
          class={[
            "w-4 h-4 transform transition-transform duration-200 ml-0",
            @active && "rotate-90"
          ]}
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          id={"#{@id}-chevron"}
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
        </svg>
      </button>

      <div
        id={@id}
        phx-mounted={@active && JS.show(to: "##{@id}")}
        class="hidden pl-11 pr-2 py-1 space-y-1"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # Dropdown Item Component
  attr :href, :string, required: true
  attr :active, :boolean, default: false
  slot :inner_block, required: true

  def dropdown_item(assigns) do
    ~H"""
    <div
      phx-click={JS.navigate(@href)}
      href={@href}
      class={[
        "flex items-center cursor-pointer px-2 py-1 text-sm font-medium rounded-md transition-all duration-200",
        if(@active,
          do: "bg-primary/20",
          else: "hover:bg-secondary/50"
        )
      ]}
    >
      <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 8h16M4 16h16" />
      </svg>
      <span>{render_slot(@inner_block)}</span>
    </div>
    """
  end

  def toggle_dropdown(js \\ %JS{}, menu_id) do
    js
    |> JS.toggle(to: menu_id)
    |> JS.toggle(
      to: "#{menu_id}",
      in: {"ease-out duration-200", "opacity-0 scale-95", "opacity-100 scale-100"},
      out: {"ease-in duration-150", "opacity-100 scale-100", "opacity-0 scale-95"}
    )
    |> JS.toggle_class("rotate-90", to: "#{menu_id}-chevron")
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Renders a dropdown component with Alpine.js.

  ## Examples

      <.dropdown id="dropdown-1" label="Options">
        <a href="#" class="block px-4 py-2">Option 1</a>
        <a href="#" class="block px-4 py-2">Option 2</a>
      </.dropdown>
  """
  attr :id, :string, required: true
  attr :class, :string, default: ""
  attr :label, :string, required: true
  slot :inner_block, required: true

  def dropdown(assigns) do
    ~H"""
    <div
      id={@id}
      x-data="dropdown"
      class={["relative", @class]}
      @close-dropdown.window="if ($event.detail.dropdownId === $el.id) open = false"
    >
      <button
        x-ref="button"
        @click="toggle"
        type="button"
        class="inline-flex items-center mb-2 text-left rounded-lg bg-[#0c2f9d] px-3 py-2 text-md font-medium text-white"
      >
        <span>{@label}</span>
        <svg
          class="w-4 h-4 ml-2 -mr-1 transition-transform duration-200"
          x-bind:class="open ? 'rotate-180' : ''"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
        >
          <path
            fill-rule="evenodd"
            d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
            clip-rule="evenodd"
          />
        </svg>
      </button>
      <template x-teleport="body">
        <div
          x-ref="dropdown"
          x-show="open"
          @click.away="open = false"
          x-transition:enter="transition ease-out duration-100"
          x-transition:enter-start="transform opacity-0 scale-95"
          x-transition:enter-end="transform opacity-100 scale-100"
          x-transition:leave="transition ease-in duration-75"
          x-transition:leave-start="transform opacity-100 scale-100"
          x-transition:leave-end="transform opacity-0 scale-95"
          class="fixed w-48 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none z-[9999]"
          style="max-height: 80vh; overflow-y: auto; transform: translateX(-16px);"
          x-init="$watch('open', value => value && $nextTick(() => updatePosition()))"
        >
          <div class="py-1 divide-y divide-gray-100">
            {render_slot(@inner_block)}
          </div>
        </div>
      </template>
    </div>
    """
  end

  # Renders sort direction icons for table headers.
  defp icon_def(filter_params, filter_item, selected_column) do
    if filter_item == selected_column do
      if filter_params["sort_order"] == "asc" do
        ~s"""
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-4 p-1 text-black">
            <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 15.75 7.5-7.5 7.5 7.5" />
          </svg>
        """
      else
        ~s"""
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-4 p-1 text-black">
            <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
          </svg>
        """
      end
    else
      ~s"""
        <div class="text-zinc-200">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 15 12 18.75 15.75 15m-7.5-6L12 5.25 15.75 9" />
          </svg>
        </div>
      """
    end
  end

  @doc """
  Renders a search field with options dropdown for filter/export.
  """
  attr :filter_params, :map, default: %{}
  attr :filter_url, :string, default: "#"
  attr :export_url, :string, default: "#"
  attr :show_filter, :boolean, default: false
  attr :show_export, :boolean, default: false

  def search_field(assigns) do
    assigns = assign(assigns, :show_options, assigns.show_filter || assigns.show_export)

    ~H"""
    <div class="row mb-1">
      <div class="flex flex-col sm:flex-row justify-between items-center w-full gap-4 sm:gap-2">
        <div class="dataTables_filter flex items-center w-full sm:w-auto">
          <div class="relative w-full sm:w-auto">
            <input
              type="search"
              value={@filter_params["search"]}
              class="w-full sm:w-auto pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              name="search"
              placeholder="Search"
              aria-describedby="basic-addon3"
              phx-keyup="search"
              phx-value-key="search"
              phx-debounce="300"
            />
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 text-gray-400 absolute left-3 top-3"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
        </div>

        <%= if @show_options do %>
          <div class="relative w-full sm:w-auto" id="options-dropdown">
            <button
              type="button"
              class="w-full sm:w-auto inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              id="options-menu"
              aria-haspopup="true"
              aria-expanded="false"
              phx-click={JS.toggle(to: "#dropdown-menu") |> JS.dispatch("options-dropdown-toggled")}
            >
              Options
              <svg
                class="-mr-1 ml-2 h-5 w-5"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fill-rule="evenodd"
                  d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>

            <div
              id="dropdown-menu"
              class="hidden origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 focus:outline-none z-50"
              role="menu"
              aria-orientation="vertical"
              aria-labelledby="options-menu"
            >
              <div class="py-1" role="none">
                <%= if @show_filter and @filter_url != "#" do %>
                  <.link
                    navigate={@filter_url}
                    class="group flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900"
                    role="menuitem"
                  >
                    <svg
                      class="mr-2 h-4 w-4 text-blue-500 group-hover:text-blue-600"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M3 3a1 1 0 011-1h12a1 1 0 011 1v3a1 1 0 01-.293.707L12 11.414V15a1 1 0 01-.293.707l-2 2A1 1 0 018 17v-5.586L3.293 6.707A1 1 0 013 6V3z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    Filter
                  </.link>
                <% end %>

                <%= if @show_export and @export_url != "#" do %>
                  <.link
                    navigate={@export_url}
                    class="group flex items-center px-3 py-1.5 text-xs text-blue-700 hover:bg-blue-50 hover:text-blue-900 rounded transition-colors"
                    role="menuitem"
                  >
                    <svg
                      class="mr-2 h-4 w-4 text-blue-500 group-hover:text-blue-600"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path d="M4 3a2 2 0 100 4h12a2 2 0 100-4H4z" />
                      <path
                        fill-rule="evenodd"
                        d="M3 8h14v7a2 2 0 01-2 2H5a2 2 0 01-2-2V8zm5 3a1 1 0 011-1h2a1 1 0 110 2H9a1 1 0 01-1-1z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    Export to Excel
                  </.link>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders pagination controls.
  """
  attr :pagination, :map, required: true
  attr :filter_params, :map, default: %{}

  def render_pagination(assigns) do
    ~H"""
    <!-- BEGIN: Pagination -->
    <div class="intro-y mb-12 mt-5 flex flex-wrap items-center sm:flex-row sm:flex-nowrap">
      <nav class="w-full ml-2 sm:mr-auto sm:w-auto">
        <ul class="flex w-full mr-0 sm:mr-auto sm:w-auto">
          <%= if @pagination[:page_number] > 1 do %>
            <li class="flex-1 sm:flex-initial">
              <a
                href={Pagination.get_priv_pagination_link(@pagination, @filter_params)}
                data-phx-link="redirect"
                data-phx-link-state="push"
                data-tw-merge=""
                class="transition duration-200 border items-center justify-center pt-4 py-3 rounded-md cursor-pointer
                 focus:ring-4 focus:ring-primary focus:ring-opacity-20 focus-visible:outline-none dark:focus:ring-slate-700
                  dark:focus:ring-opacity-50 [&:hover:not(:disabled)]:bg-opacity-90 [&:hover:not(:disabled)]:border-opacity-90
                   [&:not(button)]:text-center disabled:opacity-70 disabled:cursor-not-allowed min-w-0 sm:min-w-[40px] shadow-none
                    font-normal flex border-transparent text-slate-800 sm:mr-2 px-1 sm:px-3"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="size-3"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="m18.75 4.5-7.5 7.5 7.5 7.5m-6-15L5.25 12l7.5 7.5"
                  />
                </svg>
              </a>
            </li>
          <% else %>
            <li class="flex-1 sm:flex-initial">
              <a
                href="#"
                data-tw-merge=""
                class="transition duration-200 border items-center justify-center pt-4 py-3 rounded-md cursor-pointer
                focus:ring-4 focus:ring-primary focus:ring-opacity-20 focus-visible:outline-none dark:focus:ring-slate-700
                  dark:focus:ring-opacity-50 [&:hover:not(:disabled)]:bg-opacity-90 [&:hover:not(:disabled)]:border-opacity-90
                  [&:not(button)]:text-center disabled:opacity-70 disabled:cursor-not-allowed min-w-0 sm:min-w-[40px] shadow-none
                    font-normal flex border-transparent text-slate-400 sm:mr-2 px-1 sm:px-3"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="size-3"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="m18.75 4.5-7.5 7.5 7.5 7.5m-6-15L5.25 12l7.5 7.5"
                  />
                </svg>
              </a>
            </li>
          <% end %>

          <%= for number <- gen_page_numbers(@pagination.total_pages, @pagination.page_number) do %>
            <%= if @pagination[:page_number] == number do %>
              <li class="flex-1 sm:flex-initial">
                <a
                  data-tw-merge=""
                  class="transition duration-200 border shadow-lg items-center justify-center py-2
                                             rounded-md cursor-pointer focus:ring-4 focus:ring-primary focus:ring-opacity-20 focus-visible:outline-none
                                              dark:focus:ring-slate-700 dark:focus:ring-opacity-50 [&:hover:not(:disabled)]:bg-opacity-90
                                               [&:hover:not(:disabled)]:border-opacity-90 [&:not(button)]:text-center
                                               disabled:opacity-70 disabled:cursor-not-allowed min-w-0 sm:min-w-[40px] shadow-none font-normal flex
                                               border-transparent text-fdhBlue sm:mr-2 px-1 sm:px-3 !box dark:bg-darkmode-400"
                >
                  {number}
                </a>
              </li>
            <% else %>
              <li class="flex-1 sm:flex-initial">
                <a
                  href={Pagination.get_number_pagination_link(number, @filter_params)}
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  data-tw-merge=""
                  class="transition duration-200 border items-center justify-center py-2 rounded-md cursor-pointer focus:ring-4 focus:ring-primary
                   focus:ring-opacity-20 focus-visible:outline-none dark:focus:ring-slate-700 dark:focus:ring-opacity-50
                    [&:hover:not(:disabled)]:bg-opacity-90 [&:hover:not(:disabled)]:border-opacity-90 [&:not(button)]:text-center
                    disabled:opacity-70 disabled:cursor-not-allowed min-w-0 sm:min-w-[40px] shadow-none font-normal flex border-transparent
                    text-slate-800 sm:mr-2 px-1 sm:px-3"
                >
                  {number}
                </a>
              </li>
            <% end %>
          <% end %>

          <%= if @pagination[:page_number] < @pagination.total_pages do %>
            <li class="flex-1 sm:flex-initial">
              <a
                href={Pagination.get_next_pagination_link(@pagination, @filter_params)}
                data-phx-link="redirect"
                data-phx-link-state="push"
                data-tw-merge=""
                class="transition duration-200 border items-center justify-center pt-4 py-3 rounded-md cursor-pointer focus:ring-4 focus:ring-primary
                focus:ring-opacity-20 focus-visible:outline-none dark:focus:ring-slate-700 dark:focus:ring-opacity-50 [&:hover:not(:disabled)]:bg-opacity-90
                [&:hover:not(:disabled)]:border-opacity-90 [&:not(button)]:text-center disabled:opacity-70 disabled:cursor-not-allowed min-w-0 sm:min-w-[40px]
                 shadow-none font-normal flex border-transparent text-slate-800 sm:mr-2 px-1 sm:px-3"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="size-3"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="m5.25 4.5 7.5 7.5-7.5 7.5m6-15 7.5 7.5-7.5 7.5"
                  />
                </svg>
              </a>
            </li>
          <% else %>
            <li class="flex-1 sm:flex-initial">
              <a
                href="#"
                data-tw-merge=""
                class="transition duration-200 border items-center justify-center pt-4 py-3 rounded-md cursor-pointer focus:ring-4 focus:ring-primary
                focus:ring-opacity-20 focus-visible:outline-none dark:focus:ring-slate-700 dark:focus:ring-opacity-50 [&:hover:not(:disabled)]:bg-opacity-90
                [&:hover:not(:disabled)]:border-opacity-90 [&:not(button)]:text-center disabled:opacity-70 disabled:cursor-not-allowed min-w-0 sm:min-w-[40px]
                 shadow-none font-normal flex border-transparent text-slate-400 sm:mr-2 px-1 sm:px-3"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="size-3"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="m5.25 4.5 7.5 7.5-7.5 7.5m6-15 7.5 7.5-7.5 7.5"
                  />
                </svg>
              </a>
            </li>
          <% end %>
        </ul>
      </nav>

      <form>
        <select
          name="page_size"
          phx-change="page_size"
          data-tw-merge=""
          class="disabled:bg-slate-100 disabled:cursor-not-allowed disabled:dark:bg-darkmode-800/50 [&[readonly]]:bg-slate-100 [&[readonly]]:cursor-not-allowed [&[readonly]]:dark:bg-darkmode-800/50 transition duration-200 ease-in-out text-sm border-slate-200 shadow-sm rounded-md py-2 px-3 pr-8 focus:ring-4 focus:ring-primary focus:ring-opacity-20 focus:border-primary focus:border-opacity-40 dark:bg-darkmode-800 dark:border-transparent dark:focus:ring-slate-700 dark:focus:ring-opacity-50 group-[.form-inline]:flex-1 !box mt-3 w-20 sm:mt-0"
        >
          <%= for size <- show_options() do %>
            <%= if size == @filter_params["page_size"] do %>
              <option selected>{size}</option>
            <% else %>
              <option>{size}</option>
            <% end %>
          <% end %>
        </select>
      </form>
    </div>
    <!-- END: Pagination -->
    """
  end

  @doc """
  Generates page numbers for pagination.
  """
  def gen_page_numbers(total_pages, current_page) do
    max_visible = 5
    start = max(1, current_page - div(max_visible, 2))
    finish = min(total_pages, start + max_visible - 1)
    start = max(1, finish - max_visible + 1)
    Enum.to_list(start..finish)
  end

  @doc """
  Returns page size options.
  """
  def show_options, do: [10, 25, 50, 100]

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(CuzCoreConnectWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CuzCoreConnectWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
