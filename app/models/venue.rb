class Venue < ApplicationRecord
	has_many :players, dependent: :nullify
end
