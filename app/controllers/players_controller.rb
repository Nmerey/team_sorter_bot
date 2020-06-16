class PlayerController < ApplicationController
	def index
		@players = Player.all
	end
end
