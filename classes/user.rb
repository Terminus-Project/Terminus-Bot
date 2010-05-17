class IRCUser
  attr_writer :nick, :ident, :host, :lastMessage
  attr_reader :nick, :ident, :host, :lastMessage

  def initialize(fullString)
    parts = fullString.match(/(.*)!(.*)@(.*)/)
    @nick = parts[1]
    @ident = parts[2]
    @host = parts[3]
  end

end
