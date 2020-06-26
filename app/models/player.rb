class Player < ApplicationRecord
	has_many :matches, dependent: :destroy
	validates_uniqueness_of :t_id, on: :create
end