class AddMatchToVenue < ActiveRecord::Migration[5.0]
  def change
    add_reference :venues, :match, foreign_key: true
  end
end
