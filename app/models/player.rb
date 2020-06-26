class Player < ApplicationRecord
	has_many :matches
	validates_uniqueness_of :t_id, on: :create
end