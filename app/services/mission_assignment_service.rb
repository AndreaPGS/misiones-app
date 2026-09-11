# frozen_string_literal: true

# Encapsulates all business logic around MissionAssignment lifecycle.
#
# Operations:
#   assign(guest)                      — auto-assign a valid mission
#   change(guest)                      — abandon current, assign a new one
#   complete(assignment)               — mark done, award points
#   assign_manual(guest, mission)      — admin assigns a specific mission
#
# Every public method returns a ServiceResult.
class MissionAssignmentService
  # --- Public interface ---------------------------------------------------

  # Auto-assign a random valid mission to a guest.
  # Fails if the guest already has an active assignment.
  def self.assign(guest)
    return ServiceResult.fail("El invitado ya tiene una misión activa.") if guest.active_assignment.present?

    mission = find_valid_mission_for(guest)
    return ServiceResult.fail("No hay misiones disponibles para este invitado.") if mission.nil?

    assignment = MissionAssignment.create!(
      guest: guest,
      mission: mission,
      status: :assigned
    )

    ServiceResult.ok(assignment)
  rescue ActiveRecord::RecordInvalid => e
    ServiceResult.fail(e.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotUnique
    ServiceResult.fail("La misión ya fue asignada a otro invitado.")
  end

  # Abandon the current assignment and assign a new one.
  # Consumes one attempt.
  # Fails if guest has no attempts left or no active assignment.
  def self.change(guest)
    unless guest.active_assignment.present?
      return ServiceResult.fail("El invitado no tiene una misión activa.")
    end

    unless guest.attempts > 0
      return ServiceResult.fail("Ya no tienes intentos de cambio disponibles.")
    end

    result = nil
    no_missions = false

    ActiveRecord::Base.transaction do
      current = guest.active_assignment
      current.update!(status: :abandoned)
      guest.decrement!(:attempts)

      # Reload so active_assignment cache is cleared
      guest.reload

      mission = find_valid_mission_for(guest, exclude_mission_id: current.mission_id)

      if mission.nil?
        no_missions = true
        raise ActiveRecord::Rollback
      end

      assignment = MissionAssignment.create!(
        guest: guest,
        mission: mission,
        status: :assigned
      )

      result = ServiceResult.ok(assignment)
    end

    no_missions ? ServiceResult.fail("No hay misiones disponibles para este invitado.") : result
  rescue ActiveRecord::RecordInvalid => e
    ServiceResult.fail(e.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotUnique
    ServiceResult.fail("La misión ya fue asignada a otro invitado.")
  end

  # Mark an assignment as completed and award points.
  # Only callable from admin.
  def self.complete(assignment)
    unless assignment.assigned?
      return ServiceResult.fail("Solo se puede completar una misión activa.")
    end

    ActiveRecord::Base.transaction do
      assignment.update!(
        status: :completed,
        completed_at: Time.current
      )
      assignment.guest.increment!(:points, assignment.mission.score)
    end

    ServiceResult.ok(assignment)
  rescue ActiveRecord::RecordInvalid => e
    ServiceResult.fail(e.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotUnique
    ServiceResult.fail("La misión ya fue asignada a otro invitado.")
  end

  # Admin manually assigns a specific mission to a guest.
  # Bypasses the random-selection logic but still enforces:
  #   - guest has no active assignment
  #   - mission is active
  #   - guest is not in mission's restricted_guests
  #   - mission has never been assigned
  def self.assign_manual(guest, mission)
    if guest.active_assignment.present?
      return ServiceResult.fail("El invitado ya tiene una misión activa.")
    end

    unless mission.active?
      return ServiceResult.fail("La misión está desactivada.")
    end

    if mission.restricted_guests.exists?(guest.id)
      return ServiceResult.fail("Este invitado tiene restricción para esa misión.")
    end

    if MissionAssignment.exists?(mission_id: mission.id)
      return ServiceResult.fail("La misión ya fue asignada a otro invitado.")
    end

    assignment = MissionAssignment.create!(
      guest: guest,
      mission: mission,
      status: :assigned
    )

    ServiceResult.ok(assignment)
  rescue ActiveRecord::RecordInvalid => e
    ServiceResult.fail(e.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotUnique
    ServiceResult.fail("La misión ya fue asignada a otro invitado.")
  end

  # --- Private helpers ----------------------------------------------------

  # Find an active mission that:
  #   1. is marked active
  #   2. the guest is NOT in restricted_guests
  #   3. excludes missions already assigned to any guest
  #   4. optionally excludes a specific mission (used on change to avoid re-assigning same one)
  #
  # Returns a Mission or nil.
  def self.find_valid_mission_for(guest, exclude_mission_id: nil)
    # IDs of missions where this guest is restricted
    restricted_ids = Mission
      .joins("INNER JOIN guests_missions gm ON gm.mission_id = missions.id")
      .where("gm.guest_id = ?", guest.id)
      .pluck(:id)

    # A mission is unique across all guests, including completed/abandoned history.
    already_assigned_ids = MissionAssignment.distinct.pluck(:mission_id)

    candidates = Mission
      .active
      .where.not(id: restricted_ids)
      .where.not(id: already_assigned_ids)

    candidates = candidates.where.not(id: exclude_mission_id) if exclude_mission_id

    # If no unassigned missions remain, there is no valid mission to assign.
    if candidates.empty?
      return nil
    end

    candidates.order("RANDOM()").first
  end
  private_class_method :find_valid_mission_for
end
