class CreateMissionsTargetGuests < ActiveRecord::Migration[8.1]
  def change
    create_table :missions_target_guests, id: false do |t|
      t.references :mission, null: false, foreign_key: true
      t.references :guest, null: false, foreign_key: true
    end

    add_index :missions_target_guests, [ :mission_id, :guest_id ], unique: true
  end
end
