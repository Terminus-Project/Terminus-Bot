
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


def initialize
  register_script("Bot to user response time checker.")

  register_command("ping", :cmd_ping,  0,  0, "Measure the time it takes for the bot to receive a reply to a CTCP PING from your client.")

  register_event("NOTICE", :on_notice)

  @pending = Hash.new
end

def on_notice(msg)
  unless @pending.has_key? msg.connection.name
    return
  end

  unless @pending[msg.connection.name][msg.nick]
    return
  end

  if msg.text.start_with? "\01PING"
    time = Time.now.to_f - @pending[msg.connection.name][msg.nick]
    @pending[msg.connection.name].delete(msg.nick)

    msg.reply("Your ping time: #{sprintf("%2.4f", time)} seconds.")
  end
end

def cmd_ping(msg, params)
  @pending[msg.connection.name] ||= Hash.new

  if @pending[msg.connection.name].has_key? msg.nick
    if Time.now.to_f - @pending[msg.connection.name][msg.nick] > 30
      @pending[msg.connection.name].delete(msg.nick)
    else
      msg.reply("I'm still waiting on a reply to the last ping I sent you. (It will expire 30 seconds after it was sent.)")
      return
    end
  end

  msg.raw("PRIVMSG #{msg.nick} :\01PING\01")

  # Get a fresh time for slightly increased accuracy.
  @pending[msg.connection.name][msg.nick] = Time.now.to_f
end
