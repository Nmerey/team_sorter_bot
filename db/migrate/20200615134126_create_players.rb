class CreatePlayers < ActiveRecord::Migration[5.0]
  def change
    create_table :players do |t|
      t.string :name
      t.integer :rating
      t.string :t_id
      t.references :venue
      t.boolean :is_friend
      t.string :friend_id
      t.string :integer

      t.timestamps
    end
  end
end
