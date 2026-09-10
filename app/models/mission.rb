# frozen_string_literal: true

class Mission < ApplicationRecord
  # Associations
  belongs_to :target, class_name: "Guest"

  has_and_belongs_to_many :restricted_guests,
                          class_name: "Guest",
                          join_table: "guests_missions",
                          foreign_key: "mission_id",
                          association_foreign_key: "guest_id"

  has_and_belongs_to_many :target_guests,
                          class_name: "Guest",
                          join_table: "missions_target_guests",
                          foreign_key: "mission_id",
                          association_foreign_key: "guest_id"

  has_many :mission_assignments, dependent: :destroy

  # Validations
  validates :description, presence: true
  validates :score, numericality: { greater_than: 0 }
  validates :active, inclusion: { in: [ true, false ] }

  # Scopes
  scope :active, -> { where(active: true) }
end
