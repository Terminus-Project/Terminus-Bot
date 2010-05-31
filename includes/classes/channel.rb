
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

  attr_reader :name, :users, :bans, :key, :banExempt, :inviteExempt
  attr :topic, :modes, :limit

  def initialize(name)
    $log.debug('channel') { "New channel: #{name}" }
    @name = name
    @users = Hash.new
    @topic = ""
    @key = ""
    @modes = Array.new
    @bans = Array.new
    @banExempt = Array.new
    @inviteExempt = Array.new
  end

  def join(user)
    $log.debug('channel') { "User #{user} joined #{@name}" }
    @users[user.nick] = user unless @users.include? user
  end

  def part(user)
    $log.debug('channel') { "User #{user} parted #{@name}" }
    @users.delete user.nick
  end

  def nickChange(oldNick, newNick)
    $log.debug('channel') { "Nick change #{oldNick} -> #{newNick} in #{@name}" }
    user = @users[oldNick]
    user.nick = newNick
    @users[newNick] = user
    @users.delete oldNick
  end

  def isOn?(user)
    @users.each { |u|
      return u if user == u
    }
  end

  def to_s
   "#{@name} #{@modes} [#{@users.values.join(", ")}]"
  end

  def addBan(mask)
    @bans << mask unless @bans.include? mask
  end

  def addBanExempt(mask)
    @banExempt << mask unless @banExempt.include? mask
  end

  def addInviteExempt(mask)
    @inviteExempt << mask unless @inviteExempt.include? mask
  end


  def nickModeChange(mode, nick, plus)
    u = @users[nick]
    if plus
      u.channelModes << mode
    else
      u.channelModes.delete mode
    end
    return u
  end

  def modeChange(mode)
    $log.debug('channel') { "Mode change: #{mode}" }
    plus = true
    modeArr = mode.split(" ")

    modeArr[0].each_char { |c|
      case c
        when '+'
          plus = true
        when '-'
          plus = false
        when 'v'
          self.nickModeChange(c, modeArr[1], plus)
          modeArr.delete_at 1
        when 'h'
          self.nickModeChange(c, modeArr[1], plus)
          modeArr.delete_at 1
        when 'o'
          self.nickModeChange(c, modeArr[1], plus)
          modeArr.delete_at 1
        when 'a'
          self.nickModeChange(c, modeArr[1], plus)
          modeArr.delete_at 1
        when 'q'
          self.nickModeChange(c, modeArr[1], plus)
          modeArr.delete_at 1
        when 'b'
          if plus
            @bans << modeArr[1] unless @bans.include? modeArr[1]
          else
            @bans.delete modeArr[1]
          end
          modeArr.delete_at 1
        when 'l'
          plus ? @limit = modeArr[1] : @limit = ""
          modeArr.delete_at 1
        when 'k'
          plus ? @key = modeArr[1] : @key = ""
          modeArr.delete_at 1
        when 'e'
          if plus
            @banExempt << modeArr[1] unless @banExempt.include? modeArr[1]
          else
            @banExempt.delete modeArr[1]
          end
          modeArr.delete_at 1
        when 'I'
          if plus
            @inviteExempt << modeArr[1] unless @inviteExempt.include? modeArr[1]
          else
            @inviteExempt.delete modeArr[1]
          end
          modeArr.delete_at 1
        else
          $log.warn('channel') { "Unknown channel mode #{c}." } unless $bot.network.channelModes.include? c

          if plus
            @modes << c unless @modes.include? c
          else
            @modes.delete c
          end
      end
    }
  end

end
