class PlayersController < ApplicationController
	def index
		@players = Player.where(friend_id: nil)
	end

	def edit
		@player = Player.find(params[:id])
	end

	def update
		@player = Player.find(params[:id])
		@player.rating.nil? ? @old_rating = 0 : @old_rating = @player.rating
		@rating = (params[:player][:rating].to_i + @old_rating) / 2

		if @player.update(rating: @rating)
			redirect_to root_path
			flash[:success] = "Rating saved" 
		else
			flash[:alert] = "Not saved!"
		end

	end

end
