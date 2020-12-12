class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  before_action :set_venue, 
    if: Proc.new { |res| res.action_name =~ /^(get)_*/  }

  def futboll!(*)
    if validate_admin?
      if Venue.where(owner_id: from[:id], chat_title: chat[:title]).exists?
        @venue      = Venue.find_by(chat_title: chat[:title], owner_id: from[:id])
        @venue.players.where.not(friend_id: nil).destroy_all
        @venue.matches.destroy_all
        respond_with :message, text: "Location?"
        save_context :get_location
      else
        @venue = Venue.create(owner_id: from['id'], chat_title: chat[:title])
        respond_with :message, text: "Location?"
        save_context :get_location
      end
      session[:venue_id] = @venue.id
    end
  end

  def get_location(*location)
    @venue.location = location.join(" ")
    @venue.save

    respond_with :message, text: "Date? (DD.MM)"
    save_context :get_date
  end

  def get_date(date)
    @date 		  = [date,Date.today.year.to_s].join(".").to_date.strftime("%A %d.%m")
    @venue.date = @date || date 
    @venue.save

    respond_with :message, text: "Time? "
    save_context :get_time
  end

  def get_time(time)
    @venue.time = time
    @title      = ["Location: #{@venue.location}", "Date: #{@venue.date}", "Time: #{@venue.time}"].join("\n")
    @text       = @title + get_list(@venue.players)
    @venue.save
    
    respond_with :message, text: @text, reply_markup: {
      inline_keyboard: [
        [
          {text: '+', callback_data: "+" + "#{@venue.id}"},
          {text: '-', callback_data: "-" + "#{@venue.id}"},
        ],
        [
          {text: 'Add Friend', callback_data: "f" + "#{@venue.id}"},
          {text: "Remove Friend", callback_data: "r" + "#{@venue.id}"},
        ],
        [
          {text: "Sort Teams", callback_data: "s" + "#{@venue.id}"},
        ],
      ],
    }
  end

  def get_teams(*data)

    @venue.teams          = data[0].to_i
    @venue.players_count  = data[1].to_i
    @venue.save

    if @venue.players.count >= @venue.players_count
      @players  = @venue.players.includes(:matches).order("matches.created_at")
      @sorted_teams = sort_teams(@players)
      @list         = ""
      @sorted_teams.each_with_index do |team, i|
        @list += "\nTEAM #{i+1}\n"
        team.each_with_index do |player, i|
          @list += "#{i+1}. #{player.name}\n"
        end
      end

      respond_with :message, text: @list

    else
      answer_callback_query("Something went wrong!")
    end
    
  end

  def callback_query(data)

    @venue    = Venue.find(data[1..])
    from['username'].nil? ? @username = nil : @username = "@#{from['username']}"
    @fullname = [from['first_name'], from['last_name'], @username ].join(" ")

    if data[0] == '+'

      if Player.exists?(t_id: from['id'])

        @player = Player.find_by_t_id(from['id'])
        @match  = Match.create(player: @player, venue: @venue)

      else
        @player = Player.create(name: @fullname, t_id: from['id'], username: from['username'])
        @match  = Match.create(player: @player, venue: @venue)
      end

      show_edit_reply(data)

    elsif data[0] == '-'

      @player   = Player.find_by_t_id(from['id'])
      @match    = Match.find_by(player: @player, venue: @venue)

      @match.destroy
      show_edit_reply(data)

    elsif data[0] == 'f'

      session[:venue_id]  = @venue.id
      session[:callback]  = payload["message"]
      session[:friend_id] = from['id']

      respond_with :message, text: "Name and Rating form 1 to 10 like so: \n Chapa 0"
      save_context :add_friend

    elsif data[0] == 'r'

      @player               = @venue.players.where(friend_id: from['id']).first.destroy

      show_edit_reply(data)

    elsif data[0] == 's'

      session[:venue_id] = @venue.id

      if validate_admin?
       respond_with :message, text: "Teams and Players like so \n 3 15"
       save_context :get_teams
      end

   end
 end

 def add_friend(*data)
  @player             = Player.new(name: data[0], rating: data[1], t_id: rand(100000), friend_id: session[:friend_id], is_friend: true)
  payload["message"]  = session[:callback]

  if @player.save

    @match = Match.new(player: @player, venue_id: session[:venue_id])
    @match.save ? show_edit_reply("f#{session[:venue_id]}") : answer_callback_query("Something went wrong!")
  end
end

def get_list(data)

  @list     = ""
  @players  = data.includes(:matches).order("matches.created_at")

  @players.each_with_index do |player,i|
    @list   += "\n#{i+1}. #{player.name}"
  end
  @list
end

def show_edit_reply(data)

  @venue  = Venue.find(data[1..])
  @title  = ["Location: #{@venue.location}", "Date: #{@venue.date}", "Time: #{@venue.time}"].join("\n")
  @text   = @title + "\n" + get_list(@venue.players)

  edit_message :text, text: @text, reply_markup: {
    inline_keyboard: [
      [
        {text: '+', callback_data: "+" + data[1..]},
        {text: '-', callback_data: "-" + data[1..]},
      ],
      [
        {text: 'Add Friend', callback_data:     "f" + data[1..]},
        {text: "Remove Friend", callback_data:  "r" + data[1..]},
      ],
      [
        {text: "Sort Teams", callback_data: "s" + data[1..]},
      ],
    ],
  }
end

def sort_teams(players)

  @players_list     = players.first(@venue.players_count).to_a
  @players_per_team = @venue.players_count / @venue.teams
  @teams            = Array.new(@venue.teams) { Array.new }
  @temp_list        = @players.sort_by(&:rating)
  avrg              = players.sum(&:rating) / @venue.teams

  0.upto(@venue.teams - 2) do |i|
    temp_team = @players_list.combination(5).find_all{ |arr| arr.sum(&:rating) == avrg }.sample
    @teams[i] = temp_team
    @players_list = @players_list - temp_team
  end
  @teams[@venue.teams - 1] = @players_list
  @teams
end


def get_sum_point(team)

  @sum = 0

  if !team.nil?
    team.each do |player|
      @sum += player.rating
    end
  end
  @sum
end

private

def set_venue
  @venue = Venue.find(session[:venue_id])
end

def validate_admin?
  @admins = [231273192,171310419,44240768,78443700]

  if @admins.include?(from['id']) || chat[:id] == from[:id]
    return true
  else
    respond_with :message, text: "You are not admin @#{from['username']}"
    return false
  end

end

end