
#
#    Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#    Copyright (C) 2010  Terminus-Bot Development Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

#Declare to constants since we don't have enums in Ruby.
#There are more graceful solutions, but this will do for now.

#SERVER = 0
PRIVATE = 1 #don't care if it's a notice or query right now
CHANNEL = 2
#CTCP = 3

require 'date'

class IRCMessage
  attr_reader :destination, :message, :speaker, :timestamp, :msgArr, :args, :replyTo, :type, :raw

  def initialize(raw, destination, message, speaker)
    
    # TODO: We should be able to parse the message here and determine
    #       type and everything else, not do it separately for each
    #       message type.

    @raw = raw
    @destination = destination
    @message = message
    @speaker = IRCUser.new(speaker)
    @timestamp = DateTime.now
    @msgArr = message.split(" ")
    @args = @msgArr.clone()
    @args.delete_at(0)
    @args = @args.join(" ")

    #determine type, reply destination
    if $network.isChannel? destination
      @replyTo = @destination
      @type = CHANNEL
    else
      @type = PRIVATE
      @replyTo = @speaker.nick
    end

  end
end
