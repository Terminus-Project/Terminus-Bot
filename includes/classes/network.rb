
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

class Network
  attr_reader :name, :currentServer, :serverSoftware, :maxBans, :maxExempts, :maxInviteExempts, :maxNickLength, :maxChannelNameLength, :maxTopicLength, :maxKickLength, :maxAwayLength, :maxTargets, :maxModes, :channelTypes, :prefixes, :channelModes, :caseMapping, :maxChannels
  attr_writer :name, :currentServer, :serverSoftware, :maxBans, :maxExempts, :maxInviteExempts, :maxNickLength, :maxChannelNameLength, :maxTopicLength, :maxKickLength, :maxAwayLength, :maxTargets, :maxModes, :channelTypes, :prefixes, :channelModes, :caseMapping, :maxChannels

  # Check if the given string is a channel. During connection
  # to the server, most servers send a list of channel types, such
  # as #. If the given string starts with one of those types, this
  # will return true.
  # @param [String] str The string to test.
  # @return [Boolean] True if the given string is a channel.
  # @example
  #   network.isChannel? "Terminus-Bot" #=> false
  # @example
  #   network.isChannel? "#terminus-bot" #=> true
  def isChannel?(str)
    channelTypes.include? str[0] rescue false
  end

end
