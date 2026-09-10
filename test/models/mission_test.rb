require "test_helper"

class MissionTest < ActiveSupport::TestCase
  def valid_mission
    Mission.new(
      description: "Encuentra al impostor",
      score: 10,
      active: true,
      target: guests(:charlie)
    )
  end

  # --- Validations ---

  test "valid with all required fields" do
    assert valid_mission.valid?
  end

  test "invalid without description" do
    m = valid_mission
    m.description = nil
    assert_not m.valid?
    assert_includes m.errors[:description], "can't be blank"
  end

  test "invalid with blank description" do
    m = valid_mission
    m.description = "   "
    assert_not m.valid?
  end

  test "invalid without score" do
    m = valid_mission
    m.score = nil
    assert_not m.valid?
  end

  test "invalid with score of zero" do
    m = valid_mission
    m.score = 0
    assert_not m.valid?
    assert_includes m.errors[:score], "must be greater than 0"
  end

  test "invalid with negative score" do
    m = valid_mission
    m.score = -5
    assert_not m.valid?
  end

  test "valid with active false" do
    m = valid_mission
    m.active = false
    assert m.valid?
  end

  test "requires target" do
    m = valid_mission
    m.target = nil
    assert_not m.valid?
  end

  # --- Default value ---

  test "active defaults to true in database" do
    m = Mission.create!(
      description: "Test default",
      score: 5,
      target: guests(:alice)
    )
    assert m.active?
  end

  # --- Scope ---

  test "active scope returns only active missions" do
    active = Mission.active
    assert active.all? { |m| m.active? }
    assert_not_includes active, missions(:inactive_mission)
  end

  # --- Associations ---

  test "has many mission_assignments" do
    assert_respond_to missions(:espionage), :mission_assignments
  end

  test "has and belongs to many restricted_guests" do
    assert_respond_to missions(:espionage), :restricted_guests
  end

  test "has and belongs to many target_guests" do
    assert_respond_to missions(:espionage), :target_guests
  end

  test "can add and remove restricted_guests" do
    mission = missions(:espionage)
    guest = guests(:charlie)
    mission.restricted_guests << guest
    assert_includes mission.restricted_guests, guest
    mission.restricted_guests.delete(guest)
    assert_not_includes mission.reload.restricted_guests, guest
  end

  test "can add and remove target_guests" do
    mission = missions(:dance_off)
    guest = guests(:alice)
    mission.target_guests << guest
    assert_includes mission.target_guests, guest
    mission.target_guests.delete(guest)
    assert_not_includes mission.reload.target_guests, guest
  end
end
