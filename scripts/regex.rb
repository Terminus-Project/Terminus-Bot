
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
  register_script("Show corrected text with s/regex/replacement/ is used and allow searching with g/regex/.")

  register_event("PRIVMSG", :on_privmsg)
  register_event("PART",    :on_part)

  @messages = Hash.new
end

def on_part(msg)
  return unless msg.me?
  return unless @messages.has_key? msg.connection.name

  @messages[msg.connection.name].delete(msg.destination)
end

def on_privmsg(msg)
  return if msg.private? or msg.silent?

  if msg.text =~ /\Ag\/(.+)\/(.*)\Z/
    return unless @messages.has_key? msg.connection.name
    return unless @messages[msg.connection.name].has_key? msg.destination

    search, flags, opts = $1, $2, Regexp::EXTENDED

    opts |= Regexp::IGNORECASE if flags.include? "i"

    search = Regexp.new($1.gsub(/\s/, '\s'), opts)

    @messages[msg.connection.name][msg.destination].reverse.each do |message|
      if search.match(message[1])

        if message[2]
          msg.reply("* #{message[0]} #{message[1]}", false)
        else
          msg.reply("<#{message[0]}> #{message[1]}", false)
        end

        return
      end
    end

    return
  elsif msg.text =~ /\As\/(.+)\/(.*)\/(.*)\Z/
    return unless @messages.has_key? msg.connection.name
    return unless @messages[msg.connection.name].has_key? msg.destination
    replace, flags, opts = $2, $3, Regexp::EXTENDED

    opts |= Regexp::IGNORECASE if flags.include? "i"

    search = Regexp.new($1.gsub(/\s/, '\s'), opts)

    @messages[msg.connection.name][msg.destination].reverse.each do |message|
      if search.match(message[1])
        newmsg = (flags.include?("g") ? message[1].gsub(search, replace) : message[1].sub(search, replace) )

        if message[2]
          msg.reply("* #{message[0]} #{newmsg}", false)
        else
          msg.reply("<#{message[0]}> #{newmsg}", false)
        end

        return
      end
    end

    return
  end


  @messages[msg.connection.name] ||= Hash.new
  @messages[msg.connection.name][msg.destination] ||= Array.new


  if msg.text =~ /\01ACTION (.+)\01/
    @messages[msg.connection.name][msg.destination] << [msg.nick, $1,       true]
  else
    @messages[msg.connection.name][msg.destination] << [msg.nick, msg.text, false]
  end


  if @messages[msg.connection.name][msg.destination].length > 500
    @messages[msg.connection.name][msg.destination].shift
  end
end
