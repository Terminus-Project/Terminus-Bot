
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

class IRCUser
  attr_writer :nick, :ident, :host, :lastMessage, :accessLevel, :channelModes
  attr_reader :nick, :ident, :host, :lastMessage, :accessLevel, :channelModes

  include Comparable

  def initialize(fullString)
    if fullString =~ /(.*)!(.*)@(.*)/
      @nick = $1
      @ident = $2
      @host = $3
    else
      @nick = fullString
      @ident = ""
      @host = ""
    end
    @accessLevel = 0
    @channelModes = Array.new
  end

  def fullMask
    self.to_s
  end

  def partialMask
    "#{ident}@#{host}"
  end

  def to_s
    "#{nick}!#{ident}@#{host}"
  end

  def isChannelOp?
    @channelModes.include? 'o' or @channelModes.include? 'a' or @channelModes.include? 'q'
  end

  def isVoiced?
    @channelModes.include? 'v'
  end

  def isChannelOwner?
    @channelModes.include? 'q'
  end

  def isChannelHalfOp?
    @channelModes.include? 'h'
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end

end
