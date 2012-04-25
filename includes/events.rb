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
  Event = Struct.new(:name, :func, :owner)

  class EventFactory < Hash

    # Create a new event. The key in the hash table is the event name
    # which is used to run the event. The value is an array which will store
    # the multiple events that run are run when the event name is called.
    def create(owner, name, func)
      self[name] ||= Array.new

      $log.debug("events.create") { "Created event #{name}" }
      self[name] << Event.new(name, func, owner)
    end

    # Run all the events with the given name.
    def dispatch(name, msg = nil)
      return unless self.has_key? name

      $log.debug("events.run") { name }

      self[name].each do |event|
        begin
          event.owner.send(event.func, msg) if Bot::Flags.permit_message?(event.owner, msg)
        rescue => e
          $log.error("events.run") { "Error running event #{name}: #{e}" }
          $log.debug("events.run") { "Backtrace for #{name}: #{e.backtrace}" }
        end
      end
    end

    # Delete all the events owned by the given class.
    def delete_for(owner)
      self.each do |n, a|
        a.delete_if {|e| e.owner == owner}
      end
    end

  end

  Events = EventFactory.new

end
