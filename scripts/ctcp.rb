
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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
  register_script("Reply to some CTCP requests.")

  register_event("PRIVMSG", :on_privmsg)
end

def die
  unregister_script
  unregister_events
end

def on_privmsg(msg)
  if msg.text =~ /\01([^\s]+) ?(.*)\01/

    case $1

      when "VERSION"
        msg.send_notice(msg.nick, "\01VERSION #{VERSION}\01")
      
      when "URL"
        msg.send_notice(msg.nick, "\01URL http://terminus-bot.com/\01")

      when "TIME"
        # implements rfc 822 section 5 as date-time
        msg.send_notice(msg.nick, "\01TIME #{DateTime.now.strftime("%d %m %y %H:%M:%S %z")}\01")
      
      when "PING"
        msg.send_notice(msg.nick, "\01PING #{$2}\01")
      
      when "CLIENTINFO"
        msg.send_notice(msg.nick, "\01CLIENTINFO VERSION PING URL TIME\01")
      
      when "ACTION"
        # Don't do anything!
  
      else
        msg.send_notice(msg.nick, "\01ERRMSG #{$1} QUERY UNKNOWN\01")

      end

  end
end
