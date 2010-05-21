class IRCUser
  attr_writer :nick, :ident, :host, :lastMessage, :accessLevel, :channelModes
  attr_reader :nick, :ident, :host, :lastMessage, :accessLevel, :channelModes, :fullMask

  # TODO: Make sure this works everywhere, create some type of association
  #       between these objects and the IRC network. There needs to be
  #       a way to track users in multiple channels without keeping
  #       duplicates in each.

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

end
