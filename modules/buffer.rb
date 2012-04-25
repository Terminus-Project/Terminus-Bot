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

module Bot
  class BufferManager < Hash

    def initialize
      Events.register(self, :"001",   :on_registered)
      Events.register(self, :JOIN,    :on_join)
      Events.register(self, :PART,    :on_part)
      Events.register(self, :PRIVMSG, :record_message)
      Events.register(self, :NOTICE,  :record_message)
    end

    def on_registered(msg)
      self[msg.connection.name] ||= {}
    end

    def on_join(msg)
      self[msg.connection.name][msg.destination_canon] ||= []
    end

    def on_part(msg)
      self[msg.connection.name].delete(msg.destination_canon)
    end

    def record_message(msg)
      return if msg.private?

      if msg.type == :PRIVMSG

        if msg.text =~ /\01ACTION (.+)\01/
          text = $1
          type = :ACTION
        else
          text = msg.text
          type = msg.type
        end

      else
        text = msg.text
        type = msg.type
      end

      self[msg.connection.name][msg.destination_canon] << (:type => type,
                                                           :text => text,
                                                           :nick => msg.nick)
     
      # TODO: This is nasty. I am using a loop here because we might be
      # rehashed with a smaller value and have to shift it down to size. There
      # are better ways of doing this.
      while self[msg.connection.name][msg.destination_canon].length > Config[:modules][:buffer][:max_size]
        self[msg.connection.name][msg.destination_canon].shift
      end
    end

  end

  Buffer = BufferManager.new

end
