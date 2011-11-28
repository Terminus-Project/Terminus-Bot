
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
  register_script("Show corrected text with s/regex/replacement/ is used.")

  register_event("PRIVMSG", :on_privmsg)
  register_event("PART", :on_part)

  @messages = Hash.new
end

def die
  unregister_script
  unregister_events
end

def on_part(msg)
  return unless msg.me?
  return unless @messages.has_key? msg.connection.name

  @messages[msg.connection.name].delete(msg.destination)
end

def on_privmsg(msg)
  return if msg.private? or msg.silent?

  if msg.text =~ /\As\/(.+)\/(.*)\/(.*)\Z/
    return unless @messages.has_key? msg.connection.name
    return unless @messages[msg.connection.name].has_key? msg.destination
    flags = $3

    search = Regexp.new($1, Regexp::EXTENDED)
    replace = $2

    @messages[msg.connection.name][msg.destination].reverse.each do |message|
      if search.match(message[1])
        newmsg = (flags.include?("g") ? message[1].gsub(search, replace) : message[1].sub(search, replace) )

        msg.reply("<#{message[0]}> #{newmsg}", false)
        return
      end
    end

    return
  end

  unless @messages.has_key? msg.connection.name
    @messages[msg.connection.name] = Hash.new
  end

  unless @messages[msg.connection.name].has_key? msg.destination
    @messages[msg.connection.name][msg.destination] = Array.new
  end

  if msg.text =~ /\01ACTION (.+)\01/
    @messages[msg.connection.name][msg.destination] << [msg.nick, $1]
  else
    @messages[msg.connection.name][msg.destination] << [msg.nick, msg.text]
  end

  if @messages[msg.connection.name][msg.destination].length > 10
    @messages[msg.connection.name][msg.destination].shift
  end
end
