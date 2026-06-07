defmodule CuzCoreConnect.Workflows.RegistrationWorkflow do
  use Ecto.Schema
  import Ecto.Changeset
  # alias CuzCoreConnect.Repo

  schema "tbl_registration_workflows" do
    field :name, :string
    field :description, :string
    field :is_active, :boolean, default: false
    field :deleted_at, :naive_datetime

    embeds_many :flow, FlowStep, on_replace: :delete do
      field :step_no, :integer, default: 0
      field :description, :string, default: ""
      field :actionar_type, :string, default: "initiator"
      field :role_key, :string, default: nil
      field :actioner_id, :integer, default: nil
      field :required_titles, {:array, :string}, default: []
    end

    has_many :registrations, CuzCoreConnect.Registrations.Registration, foreign_key: :workflow_id

    timestamps(type: :utc_datetime)
  end

  def changeset(memo_flow, attrs \\ %{}) do
    memo_flow
    |> cast(attrs, [:name, :description, :is_active, :deleted_at])
    |> validate_required([:name])
    |> cast_embed(:flow,
      with: &flow_step_changeset/2,
      required: true,
      on_replace: :delete
    )
    |> validate_change(:flow, fn :flow, value ->
      case value do
        list when is_list(list) -> []
        _ -> [flow: {"must be a list of steps", validation: :format}]
      end
    end)
  end

  defp flow_step_changeset(flow_step, attrs) do
    flow_step
    |> cast(attrs, [:step_no, :description, :actionar_type, :role_key, :actioner_id, :required_titles])
    |> validate_required([:description, :actionar_type])
  end
end
