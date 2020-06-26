class CreateMatches < ActiveRecord::Migration[5.0]
  def change
    create_table :matches do |t|
      t.references :player, foreign_key: true
      t.references :venue, foreign_key: true

      t.timestamps
    end
  end
end
