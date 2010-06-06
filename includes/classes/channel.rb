
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

  attr_reader :name, :users, :bans, :key, :banExempt, :inviteExempt, :limit, :modes, :topic
  attr_writer :topic, :modes

  # Create a new Chanel object for the named channel. All relevant data structures get initialized here.
  # @param [String] name The name of the channel to be represented by this object
  # @example
  # chan = Channel.new("#terminus-bot")
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

  # Add a user to this channel object.
  # @param [IRCUser] user The object representing the user that is joining.
  def join(user)
    $log.debug('channel') { "User #{user} joined #{@name}" }
    @users[user.nick] = user unless @users.include? user
  end

  # Remove a user from this channel object.
  # @param [IRCUser] user The object representing the user that is parting.
  def part(user)
    $log.debug('channel') { "User #{user} parted #{@name}" }
    @users.delete user.nick
  end

  # Change a user's nick in this channel. The change affects both the
  # index in the user list and the nick in the user object.
  # @param [String] oldNick The nick from which the user is changing.
  # @param [String] newNick The nick to which the user is changing.
  # @example Changing a nick in one of the core channel objects.
  #   $bot.channels["#terminus-bot"].nickChange("Kabaka", "Dragon")
  def nickChange(oldNick, newNick)
    return false unless @users.key? oldNick
    $log.debug('channel') { "Nick change #{oldNick} -> #{newNick} in #{@name}" }
    user = @users[oldNick]
    user.nick = newNick
    @users[newNick] = user
    @users.delete oldNick
  end

  # Check if a user is present in this channel.
  # @param [IRCUser] user The user for which to check.
  # @return [Boolean] Returns true if the user is matched to one in this channel.
  def isOn?(user)
    @users.each { |u|
      return u if user == u
    }
  end

  # Return a string representation of this channel.
  # @return [string] "name mode_array [users]"
  def to_s
   "#{@name} #{@modes} [#{@users.values.join(", ")}]"
  end

  # Add a ban mask to the bot's list of active bans for this channel
  # @param [String] mask Hostmask that is banned from the channel.
  def addBan(mask)
    @bans << mask unless @bans.include? mask
  end

  # Add a ban mask to the bot's list of active bans exempts for this channel
  # @param [String] mask Hostmask that is exempt from bans from the channel.
  def addBanExempt(mask)
    @banExempt << mask unless @banExempt.include? mask
  end

  # Add a ban mask to the bot's list of active invite exempts for this channel
  # @param [String] mask Hostmask that is always invited to the channel.
  def addInviteExempt(mask)
    @inviteExempt << mask unless @inviteExempt.include? mask
  end


  # An internal helper method for modeChange(). When a channel
  # mode affects a user (such as +v for voice), this method
  # makes the appropriate change to the user object representing
  # that nick.
  # @param [String] mode The mode being added or removed.
  # @param [String] nick The nick which is affected by the change
  # @param [Boolean] plus True if the mode is being added, false if it is being removed.
  # @example Terminus-Bot has gained voice.
  #   nickModeChange("v", "Terminus-Bot", true)
  def nickModeChange(mode, nick, plus)
    u = @users[nick]
    if plus
      u.channelModes << mode
    else
      u.channelModes.delete mode
    end
    return u
  end

  # Change channel modes. This method will parse the full
  # channel mode change string and update user objects as
  # appropriate.
  # @param [String] mode The string containing the mode change(s).
  # @example Various mode changes
  #   chan.modeChange("+vo-k Terminus-Bot Terminus-Bot secret-key")
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
