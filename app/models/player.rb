class Player < ApplicationRecord
	belongs_to :venue, optional: true
	validates_uniqueness_of :t_id, on: :create
end
