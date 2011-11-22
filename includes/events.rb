
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

module Terminus_Bot
  class Event

    attr_reader :name, :func, :owner

    def initialize(name, func, owner)
      @name = name
      @func = func
      @owner = owner
    end

    def run(args)
      @owner.send(@func, args)
    end

  end

  class Events

    def initialize
      @events = Hash.new
    end

    def create(owner, name, func)
      unless @events.has_key? name
        @events[name] = Array.new
      end

      $log.debug("events.create") { "Created event #{name}" }
      @events[name] << Event.new(name, func, owner)
    end

    def run(name, *args)
      return unless @events.has_key? name

      $log.debug("events.run") { name }

      @events[name].each do |event|
        event.run(args[0])
      end
    end

    def delete_events_for(owner)
      @events.each do |n, a|
        a.delete_if {|e| e.owner == owner}
      end
    end
  end
end
