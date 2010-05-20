class IRCUser
  attr_writer :nick, :ident, :host, :lastMessage, :accessLevel, :channelModes
  attr_reader :nick, :ident, :host, :lastMessage, :accessLevel, :channelModes, :fullMask

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
