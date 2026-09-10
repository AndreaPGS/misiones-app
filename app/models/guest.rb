# frozen_string_literal: true

class Guest < ApplicationRecord
  # Associations
  has_many :mission_assignments, dependent: :destroy

  has_one :active_assignment,
          -> { where(status: :assigned) },
          class_name: "MissionAssignment",
          dependent: nil

  has_one :current_mission,
          through: :active_assignment,
          source: :mission

  # HABTM: missions where this guest is restricted
  has_and_belongs_to_many :restricted_in_missions,
                          class_name: "Mission",
                          join_table: "guests_missions",
                          foreign_key: "guest_id",
                          association_foreign_key: "mission_id"

  # HABTM: missions where this guest is a target_guest
  has_and_belongs_to_many :targeted_in_missions,
                          class_name: "Mission",
                          join_table: "missions_target_guests",
                          foreign_key: "guest_id",
                          association_foreign_key: "mission_id"

  # Validations
  validates :name, presence: true
  validates :points, numericality: { greater_than_or_equal_to: 0 }
  validates :attempts, numericality: { greater_than_or_equal_to: 0 }
end
