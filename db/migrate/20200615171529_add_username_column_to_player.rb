class AddUsernameColumnToPlayer < ActiveRecord::Migration[5.0]
  def change
    add_column :players, :username, :string
  end
end
