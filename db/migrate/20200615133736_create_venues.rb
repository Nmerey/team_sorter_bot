class CreateVenues < ActiveRecord::Migration[5.0]
  def change
    create_table :venues do |t|
      t.string :location
      t.string :date
      t.string :time
      t.integer :teams
      t.integer :players_count

      t.timestamps
    end
  end
end
