
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
  attr :nick, :ident, :host, :lastMessage, :accessLevel, :channelModes
  attr_reader :fullMask

  include Comparable

  def initialize(fullString)
    @fullMask = fullString
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
    @channelModes = ""
  end

  def to_s
    "#{nick}!#{ident}@#{host}"
  end

  def <=>(other)
    self.to_s <=> other.to_s
  end

end
