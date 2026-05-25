defmodule CuzCoreConnect.Registrations.RegistrationWorkflow do
  use Ecto.Schema
  import Ecto.Changeset
  # alias CuzCoreConnect.Repo

  schema "tbl_registration_workflows" do
    field :name, :string
    field :description, :string
    field :is_active, :boolean, default: true
    field :is_deleted, :boolean, default: false

    embeds_many :flow, FlowStep, on_replace: :delete do
      field :step_no, :integer, default: 0
      field :description, :string, default: ""
      field :department_type, :string, default: "initiator"
      field :department_id, :integer, default: nil
      field :required_titles, {:array, :string}, default: []
    end

    has_many :registrations, CuzCoreConnect.Registrations.Registration, foreign_key: :workflow_id

    timestamps(type: :utc_datetime)
    # timestamps(
    #   type: :naive_datetime,
    #   autogenerate: {CuzCoreConnect.LocalTimestamp, :autogenerate, []}
    # )
  end

  def changeset(memo_flow, attrs \\ %{}) do
    memo_flow
    |> cast(attrs, [:name, :description, :is_active, :is_deleted])
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
    |> cast(attrs, [:step_no, :description, :department_type, :department_id, :required_titles])
    |> validate_required([:description, :department_type])
  end

  # def seed_memo_workflow do
  #   Repo.delete_all(__MODULE__)

  #   [
  #     %__MODULE__{
  #       name: "Request to Pay for Goods or Servoces - Technology",
  #       description:
  #         "Memo Used by Innovation and Technology when requesting to Pay for Goods or Services.",
  #       is_active: true,
  #       flow: [
  #         %{
  #           id: "c632c431-f4c6-4b6a-a1cf-0ca8d1455be6",
  #           step_no: 1,
  #           description: "Memo Review and Sign",
  #           department_id: nil,
  #           department_type: "initiator",
  #           required_titles: ["Senior Officer", "Manager"]
  #         },
  #         %{
  #           id: "e4bdffec-ee55-43d2-b869-df6438df2dea",
  #           step_no: 2,
  #           description: "Memo Budget Confirmation",
  #           department_id: nil,
  #           department_type: "receiving",
  #           required_titles: ["Manager", "Director"]
  #         },
  #         %{
  #           id: "14e9d9ad-e5fb-4b1a-85de-0bf178fdcac2",
  #           step_no: 3,
  #           description: "Memo Approval",
  #           department_id: 3,
  #           department_type: "specific",
  #           required_titles: ["Chief Executive Officer"]
  #         },
  #         %{
  #           id: "1810669e-141b-4caa-b4ba-34578f9c5324",
  #           step_no: 4,
  #           description: "Initiating Payment Processing",
  #           department_id: 4,
  #           department_type: "specific",
  #           required_titles: ["Deputy Director Finance", "Manager Finance"]
  #         },
  #         %{
  #           id: "43a48073-ec67-4624-b5c8-3f0b0eae2b05",
  #           step_no: 5,
  #           description: "Memo review to verify the payment details",
  #           department_id: 4,
  #           department_type: "specific",
  #           required_titles: ["Snr Accountant"]
  #         }
  #       ]
  #     }
  #   ]
  #   |> Enum.each(fn attrs ->
  #     Repo.insert!(attrs)
  #   end)
  # end
end
