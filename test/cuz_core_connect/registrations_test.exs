defmodule CuzCoreConnect.RegistrationsTest do
  use CuzCoreConnect.DataCase, async: true

  alias CuzCoreConnect.Registrations

  import CuzCoreConnect.RegistrationFixtures
  import CuzCoreConnect.AccountFixtures

  defp hod_user, do: unconfirmed_user_fixture(%{user_role: "hod"})
  defp retention_user, do: unconfirmed_user_fixture(%{user_role: "retention"})
  defp academics_user, do: unconfirmed_user_fixture(%{user_role: "academics"})
  defp finance_user, do: unconfirmed_user_fixture(%{user_role: "finance"})

  describe "stage-skip prevention" do
    test "HOD cannot approve before academics and payment are approved" do
      registration = registration_fixture()

      assert {:error, :stage_not_ready} = Registrations.approve_hod(registration, hod_user())

      reloaded = Registrations.get_registration!(registration.id)
      assert reloaded.hod_status == "PENDING"
    end

    test "HOD can approve once academics and payment are approved" do
      registration = registration_fixture()

      {:ok, registration} = Registrations.approve_academics(registration, academics_user())
      {:ok, registration} = Registrations.approve_payment(registration, finance_user())

      assert {:ok, updated} = Registrations.approve_hod(registration, hod_user())
      assert updated.hod_status == "APPROVED"
    end

    test "Retention cannot give final approval before HOD approves" do
      registration = registration_fixture()

      assert {:error, :stage_not_ready} =
               Registrations.approve_retention(registration, retention_user())
    end

    test "full happy path reaches final APPROVED status" do
      registration = registration_fixture()

      {:ok, registration} = Registrations.approve_academics(registration, academics_user())
      {:ok, registration} = Registrations.approve_payment(registration, finance_user())
      {:ok, registration} = Registrations.approve_hod(registration, hod_user())
      {:ok, registration} = Registrations.approve_retention(registration, retention_user())

      assert registration.registration_status == "APPROVED"
      assert registration.approval_level == "approved"
    end

    test "rejection sets approval_level to rejected" do
      registration = registration_fixture()

      {:ok, rejected} =
        Registrations.reject_academics(registration, academics_user(), "Incomplete file")

      assert rejected.registration_status == "REJECTED"
      assert rejected.approval_level == "rejected"
    end
  end

  describe "audit logging" do
    test "every approval/rejection writes an insert-only audit trail row" do
      registration = registration_fixture()
      actor = academics_user()

      {:ok, _} = Registrations.approve_academics(registration, actor)

      [action] = Registrations.list_registration_actions(registration.id)
      assert action.action_type == "academics_approval"
      assert action.status == "approved"
      assert action.actionar_id == actor.id
    end

    test "rejection records the reason in the audit trail" do
      registration = registration_fixture()

      {:ok, _} =
        Registrations.reject_academics(registration, academics_user(), "Missing transcript")

      [action] = Registrations.list_registration_actions(registration.id)
      assert action.status == "rejected"
      assert action.comment == "Missing transcript"
    end
  end

  describe "rejection + resubmission" do
    test "rejecting a stage records the reason and stage, and stops the pipeline" do
      registration = registration_fixture()

      {:ok, rejected} =
        Registrations.reject_academics(registration, academics_user(), "Invalid ID")

      assert rejected.accademics_status == "REJECTED"
      assert rejected.registration_status == "REJECTED"
      assert rejected.rejection_reason == "Invalid ID"
      assert rejected.rejected_stage == "academics"
    end

    test "resubmitting a rejected registration resets the rejected stage back to PENDING" do
      registration = registration_fixture()
      student = unconfirmed_user_fixture()

      {:ok, rejected} =
        Registrations.reject_academics(registration, academics_user(), "Invalid ID")

      assert {:ok, resubmitted} = Registrations.resubmit_registration(rejected, student)
      assert resubmitted.accademics_status == "PENDING"
      assert resubmitted.registration_status == "PENDING"
      assert resubmitted.rejection_reason == nil
      assert resubmitted.rejected_stage == nil
    end

    test "cannot resubmit a registration that was never rejected" do
      registration = registration_fixture()

      assert {:error, :not_rejected} =
               Registrations.resubmit_registration(registration, unconfirmed_user_fixture())
    end
  end

  describe "bulk approval" do
    test "approves each registration individually and writes one audit row per registration" do
      actor = academics_user()
      regs = for _ <- 1..3, do: registration_fixture()

      {ok_count, errors} = Registrations.bulk_approve(regs, actor, "academics")

      assert ok_count == 3
      assert errors == []

      for reg <- regs do
        reloaded = Registrations.get_registration!(reg.id)
        assert reloaded.accademics_status == "APPROVED"
        assert length(Registrations.list_registration_actions(reg.id)) == 1
      end
    end
  end

  describe "tracking number format" do
    test "create_registration/2 generates a REG- tracking number" do
      active_workflow_fixture()

      student = unconfirmed_user_fixture()

      {:ok, registration} =
        Registrations.create_registration(student, %{
          student_id: "202612345",
          student_names: "Jane Doe",
          student_email: "jane@example.com",
          student_contact: "097123456",
          program_id: 1,
          program_name: "BSc CS",
          academic_year: 1,
          semester: 1,
          intake: "Jan",
          courses: []
        })

      assert String.starts_with?(registration.tracking_number, "REG-")

      assert Registrations.get_registration_by_tracking_number(registration.tracking_number).id ==
               registration.id
    end
  end

  describe "drafts" do
    test "save_draft creates a DRAFT without tracking number or workflow" do
      assert {:ok, draft} =
               Registrations.save_draft(
                 %{
                   student_id: "202699001",
                   student_names: "Draft Student",
                   student_email: "draft@students.cavendish.co.zm",
                   student_contact: "0977123456",
                   program_id: nil,
                   program_name: nil,
                   academic_year: nil,
                   semester: nil,
                   intake: nil,
                   courses: []
                 },
                 nil,
                 wizard_step: :programme
               )

      assert draft.registration_status == "DRAFT"
      assert is_nil(draft.tracking_number)
      assert is_nil(draft.workflow_id)
      assert draft.wizard_step == "programme"
      assert draft.payment_status == "DRAFT"
    end

    test "create_registration promotes a draft into the approval workflow" do
      active_workflow_fixture()

      {:ok, draft} =
        Registrations.save_draft(
          %{
            student_id: "202699002",
            student_names: "Draft Student",
            student_email: "draft2@students.cavendish.co.zm",
            student_contact: "0977123457",
            program_id: 1,
            program_name: "BSc CS",
            academic_year: 1,
            semester: 1,
            intake: "Jan",
            courses: []
          },
          nil,
          wizard_step: :review
        )

      assert {:ok, submitted} =
               Registrations.create_registration(
                 nil,
                 %{
                   student_id: "202699002",
                   student_names: "Draft Student",
                   student_email: "draft2@students.cavendish.co.zm",
                   student_contact: "0977123457",
                   program_id: 1,
                   program_name: "BSc CS",
                   academic_year: 1,
                   semester: 1,
                   intake: "Jan",
                   courses: []
                 },
                 draft: draft
               )

      assert submitted.id == draft.id
      assert submitted.registration_status == "PENDING"
      assert submitted.payment_status == "PENDING"
      assert String.starts_with?(submitted.tracking_number, "REG-")
      assert is_nil(submitted.wizard_step)
      assert submitted.workflow_id
    end
  end
end
