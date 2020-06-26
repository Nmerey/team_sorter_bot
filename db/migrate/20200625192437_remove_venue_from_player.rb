class RemoveVenueFromPlayer < ActiveRecord::Migration[5.0]
  def change
    remove_reference :players, :venue
  end
end
