class CreateMissionAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_assignments do |t|
      t.references :guest, null: false, foreign_key: true
      t.references :mission, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :assigned_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :mission_assignments, [ :guest_id, :status ],
              unique: true,
              where: "(status = 0)",
              name: "index_mission_assignments_on_guest_id_assigned_unique"
  end
end
