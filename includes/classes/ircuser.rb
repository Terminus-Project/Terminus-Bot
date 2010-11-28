
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

  # Create a new user object by parsing a full hostmask (nick!user@host).
  # @param [String] fullString A full hostmask in the form nick!user@host
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

  # @return [String] user@host
  def partialMask
    "#{ident}@#{host}"
  end

  # @return [String] nick!user@host
  def to_s
    "#{nick}!#{ident}@#{host}"
  end

  # @return [String] nick!user@*.host.name
  def maskedFullMask
    "#{nick}!#{self.maskedPartialMask}"
  end

  # @return [String] *.host.name
  def maskedPartialHost
    arr = host.split('.')

    if arr.length > 1
      if arr[arr.length] == "IP" and arr.length == 5
        return "#{arr[0]}#{arr[1]}.*"
      end
 
      return "*.#{arr[arr.length-2]}.#{arr[arr.length-1]}"

    end

    self.host
  end

  # @return [String] user@*.host.name
  def maskedPartialMask
    arr = host.split('.')

    if arr.length > 1
      if arr[arr.length] == "IP" and arr.length == 5
        return "#{ident}@#{arr[0]}#{arr[1]}.*"
      end
 
      return "#{ident}@*.#{arr[arr.length-2]}.#{arr[arr.length-1]}"

    end

    self.partialMask
  end

  # @return [Boolean] True if given hostmask matches nick!ident@host.
  def compareMask(mask)
    full = self.to_s
    mask = mask.gsub("*", "(.*)")
    mask = mask.gsub(".", "\.")

    full =~ /#{mask}/
  end

  # Determine if this user is a channel operator. This is
  # only useful if this object is a child of a Channel object.
  # @return [Boolean] True if channel modes contain o, a, or q.
  def isChannelOp?
    @channelModes.include? 'o' or @channelModes.include? 'a' or @channelModes.include? 'q'
  end

  # @return [Boolean] True if channel modes contain v.
  def isVoiced?
    @channelModes.include? 'v'
  end

  # @return [Boolean] True if channel modes contain q.
  def isChannelOwner?
    @channelModes.include? 'q'
  end

  # @return [Boolean] True if channel modes contain h.
  def isChannelHalfOp?
    @channelModes.include? 'h'
  end

  def adminLevel
    $bot.admins[self.partialMask].accessLevel rescue 0
  end

  # Comparison is done based on the hostmask
  # @see IRCUser#to_s
  def <=>(other)
    self.to_s <=> other.to_s
  end

  alias :fullMask :to_s
end
