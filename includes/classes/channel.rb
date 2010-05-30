
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

class Channel

  attr_reader :name, :users, :bans
  attr :topic, :key

  def initialize(name)
    $log.debug('channel') { "New channel: #{name}" }
    @name = name
    @users = Array.new
    @topic = ""
    @key = ""
    @bans = Array.new
  end

  def join(user)
    $log.debug('channel') { "User #{user} joined #{@name}" }
    @users << user unless @users.include? user
  end

  def part(user)
    $log.debug('channel') { "User #{user} parted #{@name}" }
    @users.delete user
  end

  def nickChange(oldNick, newNick)
    $log.debug('channel') { "Nick change #{oldNick} -> #{newNick} in #{@name}" }
    @users.each { |u|
      if u.nick == oldNick
        u.nick = newNick
        return u
      end
    }
  end

  def isOn?(user)
    @users.each { |u|
      return u if user == u
    }
  end

  def addBan(mask)
    @bans << mask
  end

  def to_s
   "#{@name} [#{@users.join(", ")}]"
  end

end
