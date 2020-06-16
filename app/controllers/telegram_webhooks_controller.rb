class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext

  def futboll!(*)
    if validate_admin?
      if Venue.exists?(id: from['id'])
        @venue      = Venue.find(from['id'])
        @players    = @venue.players

        @players.each do |player|
          if player.is_friend
            player.destroy
          else
            player.update(venue_id: nil)
          end  
        end

        @venue.save
        respond_with :message, text: "Location?"
        save_context :get_location
      else
        Venue.create(id: from['id'])
        respond_with :message, text: "Location?"
        save_context :get_location
      end
        
    end
  end

  def get_location(location)
    @venue          = Venue.find(from['id'])
    @venue.location = location
    @venue.save

    respond_with :message, text: "Date?"
    save_context :get_date
  end

  def get_date(date)
    @venue      = Venue.find(from['id'])
    @venue.date = date
    @venue.save

    respond_with :message, text: "Time?"
    save_context :get_time
  end

  def get_time(time)
    @venue      = Venue.find(from['id'])
    @venue.time = time
    @venue.save

    respond_with :message, text: "How many teams and players like so \n(3 15)"
    save_context :get_teams
  end

  def get_teams(*data)
    @venue                = Venue.find(from['id'])
    @venue.teams          = data[0].to_i
    @venue.players_count  = data[1].to_i
    @venue.save
    @title                = [@venue.location, @venue.date, @venue.time].join(" ")
    @text                 = @title + get_list(@venue.players)
    
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

  def callback_query(data)

    @venue    = Venue.find(data[1..])
    from['username'].nil? ? @username = nil : @username = "@#{from['username']}"
    @fullname = [from['first_name'], from['last_name'], @username ].join(" ")

    if data[0] == '+'

      if Player.exists?(t_id: from['id'])

        @player = Player.find_by_t_id(from['id'])
        @player.update(venue_id: @venue.id)

      else
        @player = Player.create(name: @fullname, t_id: from['id'],venue_id: @venue.id, username: from['username'])
      end

      @players              = @venue.players
      @title                = [@venue.location, @venue.date, @venue.time].join(" ")
      @text                 = @title + get_list(@venue.players)

      show_edit_reply(@text, data)

    elsif data[0] == '-'

      @player   = Player.find_by_t_id(from['id'])

      if @player
        @player.update(venue_id: 0)
      end

      @title                = [@venue.location, @venue.date, @venue.time].join(" ")
      @text                 = @title + get_list(@venue.players)

      show_edit_reply(@text, data)

    elsif data[0] == 'f'
      session[:venue_id]  = @venue.id
      session[:callback]  = payload["message"]
      session[:friend_id] = from['id']
      p payload['chat']
      p payload['message']
      Telegram.bot.send_message(chat_id: payload['chat']['id'], text: "Give Name and Rating like so: \n Chapa 0", reply_to_message_id: payload["message"]["id"], reply_markup: { force_reply: true, selective: true})
      save_context :add_friend

    elsif data[0] == 'r'
      @player               = @venue.players.where(friend_id: from['id']).first.destroy
      @title                = [@venue.location, @venue.date, @venue.time].join(" ")
      @text                 = @title + get_list(@venue.players)

      show_edit_reply(@text, data)

    elsif data[0] == 's'
      if validate_admin?
        @sorted_teams = sort_teams(@venue.players)
        @list         = ""
        @sorted_teams.each_with_index do |team, i|
          @list += "\n    TEAM #{i+1}\n"
          team.each_with_index do |player, i|
            @list += "#{i+1}. #{player.name}\n"
          end
        end

        respond_with :message, text: @list

      else
        answer_callback_query("You are not admin!")
      end
    end
  end

  def add_friend(*data)
    reply_with :message , text: "", reply_markup: { force_reply: true, selective: true }
    @player             = Player.new(name: data[0], rating: data[1], t_id: rand(100000),  venue_id: session[:venue_id], friend_id: session[:friend_id], is_friend: true)

    if @player.save
      @venue  = Venue.find(@player.venue_id)
      @text   = @venue.location + get_list(@venue.players)
      payload["message"]  = session[:callback]
      show_edit_reply(@text, "f#{@venue.id}")
    end
  end

  def get_list(data)
    @list = ""
    @players = data.sort_by(&:updated_at)
    @players.each_with_index do |player,i|
      @list   += "\n#{i+1}. #{player.name}"
    end
    @list
  end
  
  def show_edit_reply(players,data)
    @venue  = Venue.find(data[1..])
    @title  = [@venue.location, @venue.date, @venue.time].join(" ")
    @text   = @title + get_list(@venue.players)

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
    @players          = players.first(@venue.players_count)
    @venue            = Venue.find(players.first.venue_id)
    @players_per_team = @venue.players_count / @venue.teams
    @teams            = Array.new(@venue.teams) { Array.new }
    @temp_list        = @players.sort_by(&:rating)

    while @temp_list.any?
      0.upto(@venue.teams - 1) { |i| 
        if @temp_list.any?
          @teams[i] << @temp_list.first
          @temp_list.slice!(0)
        end
      }

      0.upto(@venue.teams - 1) { |i|
        if @temp_list.any?
          @teams[i] << @temp_list.last
          @temp_list.pop()
        end
      }

    end

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

  def validate_admin?
    @admins = [231273192,171310419]
    @admins.include?(from['id'])
  end

end