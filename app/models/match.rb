class Match < ApplicationRecord
  belongs_to :venue
  belongs_to :player
  validates :player_id, uniqueness: {scope: :venue_id, message: "cant be more than one player in list"}
end
