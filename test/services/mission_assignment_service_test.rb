require "test_helper"

class MissionAssignmentServiceTest < ActiveSupport::TestCase
  # =========================================================================
  # ServiceResult
  # =========================================================================

  class ServiceResultTest < ActiveSupport::TestCase
    test "ok returns a successful result with payload" do
      result = ServiceResult.ok("data")
      assert result.success?
      assert_not result.failure?
      assert_equal "data", result.payload
      assert_nil result.error
    end

    test "fail returns a failure result with error message" do
      result = ServiceResult.fail("algo salió mal")
      assert result.failure?
      assert_not result.success?
      assert_equal "algo salió mal", result.error
      assert_nil result.payload
    end

    test "fail can carry a payload alongside the error" do
      result = ServiceResult.fail("error", payload: :something)
      assert result.failure?
      assert_equal :something, result.payload
    end
  end

  # =========================================================================
  # assign
  # =========================================================================

  class AssignTest < ActiveSupport::TestCase
    test "assigns a valid mission to a guest with no active assignment" do
      # bob has no active assignment (his only assignment is completed)
      result = MissionAssignmentService.assign(guests(:bob))

      assert result.success?, result.error
      assert result.payload.is_a?(MissionAssignment)
      assert result.payload.assigned?
      assert_equal guests(:bob), result.payload.guest
    end

    test "returned assignment has assigned_at set" do
      result = MissionAssignmentService.assign(guests(:bob))
      assert_not_nil result.payload.assigned_at
    end

    test "fails when guest already has an active assignment" do
      # alice already has alice_assigned fixture
      result = MissionAssignmentService.assign(guests(:alice))

      assert result.failure?
      assert_match "ya tiene una misión activa", result.error
    end

    test "fails when no valid missions are available" do
      # charlie has no active assignment; mark all active missions as restricted for charlie
      Mission.active.each { |m| m.restricted_guests << guests(:charlie) }

      result = MissionAssignmentService.assign(guests(:charlie))

      assert result.failure?
      assert_match "No hay misiones disponibles", result.error
    end

    test "does not assign a mission marked inactive" do
      # Give charlie all active missions as restricted except the inactive one
      Mission.active.each { |m| m.restricted_guests << guests(:charlie) }

      result = MissionAssignmentService.assign(guests(:charlie))
      assert result.failure? # inactive_mission should NOT be assigned
    end

    test "does not assign a mission where guest is in restricted_guests" do
      # Restrict charlie from all active missions
      Mission.active.find_each { |m| m.restricted_guests << guests(:charlie) }

      result = MissionAssignmentService.assign(guests(:charlie))
      assert result.failure?
    end

    test "increments mission_assignments count on success" do
      assert_difference "MissionAssignment.count", 1 do
        MissionAssignmentService.assign(guests(:bob))
      end
    end
  end

  # =========================================================================
  # change
  # =========================================================================

  class ChangeTest < ActiveSupport::TestCase
    test "abandons current assignment and assigns a new one" do
      # alice: 2 attempts, assigned to espionage — dance_off and karaoke are available
      old_assignment = guests(:alice).active_assignment
      result = MissionAssignmentService.change(guests(:alice))

      assert result.success?, result.error
      assert old_assignment.reload.abandoned?
      assert result.payload.assigned?
      assert_not_equal old_assignment.mission_id, result.payload.mission_id
    end

    test "decrements guest attempts by one" do
      alice = guests(:alice)
      original_attempts = alice.attempts

      MissionAssignmentService.change(alice)

      assert_equal original_attempts - 1, alice.reload.attempts
    end

    test "fails when guest has no active assignment" do
      # charlie: no active assignment, 0 attempts
      result = MissionAssignmentService.change(guests(:charlie))

      assert result.failure?
      assert_match "no tiene una misión activa", result.error
    end

    test "fails when guest has zero attempts" do
      # Give charlie an active assignment but keep attempts at 0
      charlie = guests(:charlie)
      MissionAssignment.create!(
        guest: charlie,
        mission: missions(:dance_off),
        status: :assigned
      )
      charlie.reload

      result = MissionAssignmentService.change(charlie)

      assert result.failure?
      assert_match "no tienes intentos", result.error.downcase
    end

    test "rolls back everything if no replacement mission is found" do
      # alice is assigned to espionage; restrict ALL other active missions for alice
      alice = guests(:alice)
      original_attempts = alice.attempts
      original_assignment = alice.active_assignment

      # Restrict alice from every active mission except the one she already has
      Mission.active.where.not(id: original_assignment.mission_id).find_each do |m|
        m.restricted_guests << alice
      end

      result = MissionAssignmentService.change(alice)

      assert result.failure?
      # attempts should NOT have been decremented (transaction rolled back)
      assert_equal original_attempts, alice.reload.attempts
      # old assignment should still be assigned
      assert original_assignment.reload.assigned?
    end

    test "creates a new assignment record on success" do
      assert_difference "MissionAssignment.count", 1 do
        MissionAssignmentService.change(guests(:alice))
      end
    end
  end

  # =========================================================================
  # complete
  # =========================================================================

  class CompleteTest < ActiveSupport::TestCase
    test "marks assignment as completed with completed_at timestamp" do
      assignment = mission_assignments(:alice_assigned)
      result = MissionAssignmentService.complete(assignment)

      assert result.success?, result.error
      assert assignment.reload.completed?
      assert_not_nil assignment.completed_at
    end

    test "awards points equal to mission score to the guest" do
      assignment = mission_assignments(:alice_assigned)
      guest      = assignment.guest
      mission    = assignment.mission
      original_points = guest.points

      MissionAssignmentService.complete(assignment)

      assert_equal original_points + mission.score, guest.reload.points
    end

    test "fails when assignment is already completed" do
      result = MissionAssignmentService.complete(mission_assignments(:bob_completed))

      assert result.failure?
      assert_match "Solo se puede completar una misión activa", result.error
    end

    test "fails when assignment is abandoned" do
      assignment = mission_assignments(:alice_assigned)
      assignment.update!(status: :abandoned)

      result = MissionAssignmentService.complete(assignment)

      assert result.failure?
    end

    test "returns the completed assignment as payload" do
      result = MissionAssignmentService.complete(mission_assignments(:alice_assigned))
      assert_equal mission_assignments(:alice_assigned), result.payload
    end

    test "does not change points when completing an already-completed assignment" do
      bob = guests(:bob)
      original_points = bob.points

      MissionAssignmentService.complete(mission_assignments(:bob_completed))

      assert_equal original_points, bob.reload.points
    end
  end

  # =========================================================================
  # assign_manual
  # =========================================================================

  class AssignManualTest < ActiveSupport::TestCase
    test "assigns a specific active mission to a guest with no active assignment" do
      result = MissionAssignmentService.assign_manual(guests(:bob), missions(:espionage))

      assert result.success?, result.error
      assert result.payload.assigned?
      assert_equal guests(:bob), result.payload.guest
      assert_equal missions(:espionage), result.payload.mission
    end

    test "fails when guest already has an active assignment" do
      result = MissionAssignmentService.assign_manual(guests(:alice), missions(:dance_off))

      assert result.failure?
      assert_match "ya tiene una misión activa", result.error
    end

    test "fails when mission is inactive" do
      result = MissionAssignmentService.assign_manual(guests(:bob), missions(:inactive_mission))

      assert result.failure?
      assert_match "desactivada", result.error
    end

    test "fails when guest is in mission restricted_guests" do
      missions(:espionage).restricted_guests << guests(:bob)

      result = MissionAssignmentService.assign_manual(guests(:bob), missions(:espionage))

      assert result.failure?
      assert_match "restricción", result.error
    end

    test "increments mission_assignments count on success" do
      assert_difference "MissionAssignment.count", 1 do
        MissionAssignmentService.assign_manual(guests(:bob), missions(:dance_off))
      end
    end

    test "assigned_at is set automatically" do
      result = MissionAssignmentService.assign_manual(guests(:bob), missions(:espionage))
      assert_not_nil result.payload.assigned_at
    end
  end
end
