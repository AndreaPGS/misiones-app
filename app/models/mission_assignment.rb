# frozen_string_literal: true

class MissionAssignment < ApplicationRecord
  # Associations
  belongs_to :guest
  belongs_to :mission

  # Enum
  enum :status, { assigned: 0, completed: 1, abandoned: 2 }, validate: true

  # Validations
  validates :status, presence: true
  validates :guest_id, uniqueness: {
    conditions: -> { where(status: :assigned) },
    message: "already has an active mission assignment"
  }
  validates :mission_id, uniqueness: {
    message: "already has an assignment"
  }

  # Callbacks
  before_create :set_assigned_at

  private

  def set_assigned_at
    self.assigned_at ||= Time.current
  end
end
