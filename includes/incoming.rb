
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

module IRC

  class Incoming

    attr_accessor :recvq

    def initialize(bot)
      # This could be in its own class, but it will always
      # be this and always be simple, so that seems like overkill.
      @recvq = Queue.new
    
      @threads = Array.new(5) {
        Thread.new {

          $log.debug("pool") { "Thread started." }

          while true
            request = @recvq.pop

            begin
              Timeout::timeout(45){ bot.messageReceived(request) }
            rescue Timeout::Error => e
              $log.warn("pool") { "Request timed out: #{request}" }
            rescue => e
              $log.warn("pool") { "Request failed: #{e}" }
              $log.debug("pool") { e.backtrace } if $options[:debug]
            end
          end
        }
      }
    end

  end # class Incoming

end # module IRC
