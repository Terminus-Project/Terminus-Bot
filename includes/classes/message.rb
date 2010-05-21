# Class: IRCMessage
# Message, destination, speaker, etc.


#Declare to constants since we don't have enums in Ruby.
#There are more graceful solutions, but this will do for now.

#SERVER = 0
PRIVATE = 1 #don't care if it's a notice or query right now
CHANNEL = 2
#CTCP = 3

require 'date'

class IRCMessage
  attr_reader :destination, :message, :speaker, :timestamp, :msgArr, :args, :replyTo, :type, :raw

  def initialize(raw, destination, message, speaker)
    @raw = raw
    @destination = destination
    @message = message
    @speaker = IRCUser.new(speaker)
    @timestamp = DateTime.now
    @msgArr = message.split(" ")
    @args = @msgArr.clone()
    @args.delete_at(0)
    @args = @args.join(" ")

    #determine type, reply destination
    if $network.isChannel? destination
      @replyTo = @destination
      @type = CHANNEL
    else
      @type = PRIVATE
      @replyTo = @speaker.nick
    end

  end
end
