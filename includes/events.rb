#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

module Bot
  Event = Struct.new(:name, :func, :owner)

  class EventManager < Hash

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
          unless msg == nil
            next unless Bot::Flags.permit_message?(event.owner, msg)

            event.owner.send(event.func, msg)
          else
            event.owner.send(event.func)
          end

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

  Events = EventManager.new

end
