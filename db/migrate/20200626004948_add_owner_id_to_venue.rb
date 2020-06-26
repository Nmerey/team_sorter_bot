class AddOwnerIdToVenue < ActiveRecord::Migration[5.0]
  def change
    add_column :venues, :owner_id, :integer
  end
end
