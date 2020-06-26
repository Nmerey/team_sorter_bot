class AddChatTittleToVenue < ActiveRecord::Migration[5.0]
  def change
    add_column :venues, :chat_title, :string
  end
end
