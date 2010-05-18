# Class: IRCMessage
# Message, destination, speaker, etc.

require 'date'

class IRCMessage
  attr_reader :destination, :message, :speaker, :timestamp, :msgArr, :args, :replyTo

  def initialize(destination, message, speaker)
    @destination = destination
    @message = message
    @speaker = IRCUser.new(speaker)
    @timestamp = DateTime.now
    @msgArr = message.split(/ /)
    @args = @msgArr.clone()
    @args.delete_at(0)
    @args = @args.join(" ")
    if $network.isChannel? destination
      @replyTo = @destination
    else
      @replyTo = @speaker.nick
    end
  end

end
