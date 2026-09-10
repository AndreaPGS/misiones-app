class CreateMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :missions do |t|
      t.text :description, null: false
      t.integer :score, null: false
      t.boolean :active, null: false, default: true
      t.references :target, null: false, foreign_key: { to_table: :guests }

      t.timestamps
    end
  end
end
