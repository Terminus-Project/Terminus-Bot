
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

def initialize
  @pings = Hash.new

  registerModule("Ping", "Allow users to discover their latency to the bot.")

  registerCommand("Ping", "ping", "The bot will ping the user via CTCP and then announce the time taken for a reply to arrive.")
end

def cmd_ping(message)
  unless @pings[message.speaker.nick] == nil
    existing = @pings[message.speaker.nick]

    if existing["Expiration"] < Time.now.to_f
      @pings.delete existing
    else
      reply(message, "I am still waiting for a reply to my last ping. If I don't get one soon, though, I'll give up.")
      return
    end
  end

  sendCTCP(message.speaker.nick, "PING #{Time.now.to_i}")
  sent = Time.now.to_f
  @pings[message.speaker.nick] = Hash.new
  @pings[message.speaker.nick]["ReplyTo"] = message.replyTo
  @pings[message.speaker.nick]["Sent"] = sent
  @pings[message.speaker.nick]["Expiration"] = Time.now.to_i + 30
end

def bot_ctcpReply(message)
  if message.message =~ /^PING (.*)$/
    unless @pings[message.speaker.nick] == nil
      received = Time.now.to_f
      ping = @pings[message.speaker.nick]

      time = received - ping["Sent"]
      destination = ping["ReplyTo"]
      
      @pings.delete message.speaker.nick

      reply = "#{message.speaker.nick}, your ping time is #{BOLD}#{time}#{NORMAL}"

      sendPrivmsg(destination, reply)
    end
  end
end
