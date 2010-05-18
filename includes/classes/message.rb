# Class: IRCMessage
# Message, origin, speaker, etc.

require 'date'

class IRCMessage
  attr_reader :origin, :message, :speaker, :timestamp, :msgArr, :args

  def initialize(origin, message, speaker)
    @origin = origin
    @message = message
    @speaker = IRCUser.new(speaker)
    @timestamp = DateTime.now
    @msgArr = message.split(/ /)
    @args = @msgArr.clone()
    @args.delete_at(0)
    @args = @args.join(" ")
  end

end
