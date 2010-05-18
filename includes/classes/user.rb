class IRCUser
  attr_writer :nick, :ident, :host, :lastMessage, :accessLevel, :channelModes
  attr_reader :nick, :ident, :host, :lastMessage, :accessLevel, :channelModes

  def initialize(fullString)
    parts = fullString.match(/(.*)!(.*)@(.*)/)
    @nick = parts[1]
    @ident = parts[2]
    @host = parts[3]
    @accessLevel = 0
    @channelModes = ""
  end

end
