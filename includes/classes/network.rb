class Network
  attr_reader :name, :currentServer, :serverSoftware, :maxBans, :maxExempts, :maxInviteExempts, :maxNickLength, :maxChannelNameLength, :maxTopicLength, :maxKickLength, :maxAwayLength, :maxTargets, :maxModes, :channelTypes, :prefixes, :channelModes, :caseMapping, :maxChannels
  attr_writer :name, :currentServer, :serverSoftware, :maxBans, :maxExempts, :maxInviteExempts, :maxNickLength, :maxChannelNameLength, :maxTopicLength, :maxKickLength, :maxAwayLength, :maxTargets, :maxModes, :channelTypes, :prefixes, :channelModes, :caseMapping, :maxChannels

  def isChannel?(str)
    channelTypes.include? str[0] rescue false
  end

end
