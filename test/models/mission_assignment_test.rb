require "test_helper"

class MissionAssignmentTest < ActiveSupport::TestCase
  def valid_assignment(guest: guests(:charlie), mission: missions(:espionage))
    MissionAssignment.new(
      guest: guest,
      mission: mission,
      status: :assigned,
      assigned_at: Time.current
    )
  end

  # --- Validations ---

  test "valid assignment" do
    assert valid_assignment.valid?
  end

  test "invalid without guest" do
    a = valid_assignment
    a.guest = nil
    assert_not a.valid?
  end

  test "invalid without mission" do
    a = valid_assignment
    a.mission = nil
    assert_not a.valid?
  end

  test "invalid without status" do
    a = valid_assignment
    a.status = nil
    assert_not a.valid?
  end

  # --- Enum ---

  test "status enum values are correct" do
    assert_equal 0, MissionAssignment.statuses[:assigned]
    assert_equal 1, MissionAssignment.statuses[:completed]
    assert_equal 2, MissionAssignment.statuses[:abandoned]
  end

  test "assigned? predicate works" do
    assert mission_assignments(:alice_assigned).assigned?
  end

  test "completed? predicate works" do
    assert mission_assignments(:bob_completed).completed?
  end

  # --- Uniqueness: one active assignment per guest ---

  test "guest cannot have two assigned assignments simultaneously" do
    # alice already has an assigned assignment (alice_assigned fixture)
    duplicate = MissionAssignment.new(
      guest: guests(:alice),
      mission: missions(:dance_off),
      status: :assigned,
      assigned_at: Time.current
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:guest_id], "already has an active mission assignment"
  end

  test "guest can have a second assignment if first is completed" do
    new_assignment = MissionAssignment.new(
      guest: guests(:bob),
      mission: missions(:espionage),
      status: :assigned,
      assigned_at: Time.current
    )
    assert new_assignment.valid?
  end

  test "guest can have a second assignment if first is abandoned" do
    alice = guests(:alice)
    alice.active_assignment.update!(status: :abandoned)

    new_assignment = MissionAssignment.new(
      guest: alice,
      mission: missions(:dance_off),
      status: :assigned,
      assigned_at: Time.current
    )
    assert new_assignment.valid?
  end

  test "multiple completed assignments for same guest are valid" do
    second = MissionAssignment.new(
      guest: guests(:bob),
      mission: missions(:espionage),
      status: :completed,
      assigned_at: 2.hours.ago,
      completed_at: 1.hour.ago
    )
    assert second.valid?
  end

  # --- Callback ---

  test "assigned_at is set automatically on create" do
    a = MissionAssignment.create!(
      guest: guests(:charlie),
      mission: missions(:espionage),
      status: :assigned
    )
    assert_not_nil a.assigned_at
  end

  test "assigned_at is not overwritten if already set" do
    fixed_time = 1.day.ago
    a = MissionAssignment.create!(
      guest: guests(:charlie),
      mission: missions(:espionage),
      status: :assigned,
      assigned_at: fixed_time
    )
    assert_in_delta fixed_time.to_i, a.assigned_at.to_i, 1
  end

  # --- Associations ---

  test "belongs to guest" do
    assert_equal guests(:alice), mission_assignments(:alice_assigned).guest
  end

  test "belongs to mission" do
    assert_equal missions(:espionage), mission_assignments(:alice_assigned).mission
  end
end
