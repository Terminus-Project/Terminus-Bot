#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

require 'json'

raise "xbox script requires the http_client module" unless defined? MODULE_LOADED_HTTP

register 'Retrieve information about Xbox Live players.'

command 'xbox', 'Retrieve information about Xbox Live players. Syntax: PROFILE gamertag|ACHIEVEMENTS gamertag [game]|FRIENDS gamertag' do
  argc! 2

  case @params.first.downcase.to_sym
  when :profile
    profile @params.last
  when :achievements
    achievements *@params.last.split(/\s/, 2)
  when :friends
    friends @params.last
  end
end


helpers do
  def profile gamertag
    api_call('profile', gamertag) do |json|
      data = {
        json['Gamertag'] => {
        'Status' => json['OnlineStatus'].gsub(/\s+/, ' '),
        'Gamer Score' => json['GamerScore'],
        'Tier' => json['Tier']
        }
      }

      reply data
    end
  end

  def achievements gamertag, game = nil
    api_call('games', gamertag) do |json|
      catch :game_found do

        unless game.nil?
          game.downcase!

          json['PlayedGames'].each do |game_json|

            if game_json['Title'].downcase == game
              game_achievements game_json
              throw :game_found
            end

          end

          raise "That game has not been played."
        end

        data = {
          'Games Played' => json['GameCount'],
          'Gamer Score'  => "#{json['TotalEarnedGamerScore']}/#{json['TotalPossibleGamerScore']}",
          'Achievements' => "#{json['TotalEarnedAchievements']}/#{json['TotalPossibleAchievements']}",
          'Completion'   => "#{json['TotalPercentCompleted']}%"
        }

        reply data

      end
    end
  end

  def game_achievements json
      data = {
        'Title' => json['Title'],
        'Gamer Score'  => "#{json['EarnedGamerScore']}/#{json['PossibleGamerScore']}",
        'Achievements' => "#{json['EarnedAchievements']}/#{json['PossibleAchievements']}",
        'Completion'   => "#{json['PercentageCompleted']}%",
        'Last Played'  => "#{Time.at(json['LastPlayed']).to_duration_s} ago"
      }

      reply data
  end

  def friends gamertag
    api_call('friends', gamertag) do |json|
      arr = []

      json['Friends'].each do |friend|
        online = friend['IsOnline'] ? 'Online' : 'Offline'

        arr << "#{friend['Gamertag']} (#{online})"
      end

      data = {
        "#{json['TotalFriends']} Friends" => arr.join(', ')
      }

      reply data
    end
  end

  def api_call func, gamertag
    uri = URI("http://www.xboxleaders.com/api/#{func}.json")

    query = {
      :gamertag => gamertag
    }


    http_get(uri, query) do |http|
      json = JSON.parse(http.response)

      unless json.has_key? 'Data'
        raise 'Player not found.'
      end

      yield json['Data']
    end
  end
end
