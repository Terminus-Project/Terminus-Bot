
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

ChannelUser = Struct.new(:nick, :user, :host)

class Channel

  attr_reader :name, :topic, :modes, :key, :users

  # Create the channel object. Since all we know when we join is the name,
  # that's all we're going to store here.
  def initialize(name)
    @name = name

    @topic, @key, @modes, @users = "", "", [], []
  end

  # Parse mode changes for the channel. The modes are extracted elsewhere
  # and sent here.
  def mode_change(modes)
    $log.debug("Channel.mode_change") { "Changing modes for #{@name}: #{modes}" }

    plus = true

    # TODO: Handle modes with args (bans, ops, etc.) correctly.
    #       More data structures will be necessary to store that
    #       data. If we're going to parse bans and such, we'll
    #       also need to request a ban list on JOIN, and also
    #       parse the modes that can have such lists from the 003
    #       message from the server. This was done in the old Terminus-Bot
    #       but hasn't been ported yet.

    with_params, index = [], 0

    modes[0].each_char do |mode|

      case mode
      when "+"
        plus = true

      when "-"
        plus = false

      when " "
        # This should never happen. (TODO: Remove? --Kabaka)
        break

      else
        if plus
          @modes << mode
        else
          @modes.delete(mode)
        end

      end
    end

    modes[1..-1].each do |param|
      if with_params.empty?
        $log.warn("Channel.mode_change") { "Mode change parameter with no valid mode: #{param}" }
        next
      end

      key = with_params.shift
      $log.debug("Channel.mode_change") { "#{key} => #{param}" }
    end
  end

  # Store the topic.
  def topic(str)
    @topic = str
  end

  # Add a user to our channel's user list.
  def join(user)
    return if @users.select {|u| u.nick == user.nick}.length > 0

    $log.debug("Channel.join") { "#{user.nick} joined #{@name}" }
    @users << user
  end

  # Remove a user from our channel's user list.
  def part(nick)
    $log.debug("Channel.part") { "#{nick} parted #{@name}" }
    @users.delete_if {|u| u.nick == nick}
  end

  # Retrieve the channel user object for the named user, or return nil
  # if none exists.
  def get_user(nick)
    results = @users.select {|u| u.nick == nick}

    return results.empty? ? nil : results[0]
  end
end
