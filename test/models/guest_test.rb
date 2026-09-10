require "test_helper"

class GuestTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid with all required fields" do
    guest = Guest.new(name: "Diana", points: 0, attempts: 1)
    assert guest.valid?
  end

  test "invalid without name" do
    guest = Guest.new(points: 0, attempts: 1)
    assert_not guest.valid?
    assert_includes guest.errors[:name], "can't be blank"
  end

  test "invalid with negative points" do
    guest = Guest.new(name: "Diana", points: -1, attempts: 1)
    assert_not guest.valid?
    assert_includes guest.errors[:points], "must be greater than or equal to 0"
  end

  test "invalid with negative attempts" do
    guest = Guest.new(name: "Diana", points: 0, attempts: -1)
    assert_not guest.valid?
    assert_includes guest.errors[:attempts], "must be greater than or equal to 0"
  end

  test "valid with zero points and zero attempts" do
    guest = Guest.new(name: "Diana", points: 0, attempts: 0)
    assert guest.valid?
  end

  # --- Default values ---

  test "points defaults to 0 in database" do
    guest = Guest.create!(name: "Eve")
    assert_equal 0, guest.points
  end

  test "attempts defaults to 1 in database" do
    guest = Guest.create!(name: "Eve")
    assert_equal 1, guest.attempts
  end

  # --- Associations ---

  test "has many mission_assignments" do
    alice = guests(:alice)
    assert_respond_to alice, :mission_assignments
    assert_equal 1, alice.mission_assignments.count
  end

  test "active_assignment returns only assigned status" do
    alice = guests(:alice)
    assert_not_nil alice.active_assignment
    assert alice.active_assignment.assigned?
  end

  test "active_assignment is nil when no active assignment" do
    bob = guests(:bob)
    assert_nil bob.active_assignment
  end

  test "current_mission returns the active mission" do
    alice = guests(:alice)
    assert_equal missions(:espionage), alice.current_mission
  end

  test "current_mission is nil when no active assignment" do
    bob = guests(:bob)
    assert_nil bob.current_mission
  end
end
