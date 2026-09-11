class AddUniqueMissionAssignmentIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :mission_assignments, :mission_id,
              unique: true,
              name: "index_mission_assignments_on_mission_id_unique"
  end
end