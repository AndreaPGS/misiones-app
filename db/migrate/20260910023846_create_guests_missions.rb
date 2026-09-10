class CreateGuestsMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :guests_missions, id: false do |t|
      t.references :guest, null: false, foreign_key: true
      t.references :mission, null: false, foreign_key: true
    end

    add_index :guests_missions, [ :guest_id, :mission_id ], unique: true
  end
end
