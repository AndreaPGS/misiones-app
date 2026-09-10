class CreateGuests < ActiveRecord::Migration[8.1]
  def change
    create_table :guests do |t|
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :picture
      t.integer :points, null: false, default: 0
      t.integer :attempts, null: false, default: 1

      t.timestamps
    end
  end
end
