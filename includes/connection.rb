
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

  class Connection

    attr_reader :socket, :readThread

    def initialize(bot, host, port, bind = nil)
      $log.debug('connection') { "Creating a new IRC connection to #{host}:#{port}#{" via #{bind}" if bind}." }

      @bot = bot

      @host = host
      @port = port

      @socket = TCPSocket.open(host, port, bind)

      raw "NICK " + @bot.config["Nick"]
      raw "USER #{@bot.config["UserName"]} 0 * #{@bot.config["RealName"]}"

      $log.debug('connection') { 'Successfully connected.' }

      @incoming = Incoming.new(bot)
      
      @bot.scheduler.add("Keep-Alive Pinger", Proc.new { self.raw("PING #{Time.now.to_i}") }, 360, true)

      @sendThread = self.startSendThread
      @readThread = self.startReadThread
    end

    def raw(str)
      @socket.puts str if @socket
    end

    def startReadThread()
      return Thread.new {

        $log.debug('connection') { "Socket reader thread started." }

        until @socket.eof? do
          msg = @socket.gets.chomp
          puts msg unless $options[:fork]

          # Go ahead and handle server PING first!
          # We don't want to get a ping timeout because
          # the queue is full.
          if msg =~ /^PING (:.*)$/
            raw "PONG #{$1}"
            next
          end

          # Throw it in the pool!
          @incoming.recvq << msg
        end

        $log.info('connection') { "Connection to #{@host}:#{@port} has been lost." }
      }
    end

    def startSendThread
      @sendq = Queue.new

        Thread.new {
          $log.debug('outgoing') { "Thread started." }
          while true          
            begin
              while true
                msg = @sendq.pop
                $log.debug('outgoing') { "Sent: #{msg}" }
                self.raw(msg)
                sleep @bot.config["Throttle"]
              end
            rescue => e
              $log.error('outgoing') { "Thread crashed: #{e}" }
            end
            $log.debug('outgoing') { "Restarting thread." }
          end
          $log.debug('outgoing') { "Thread stopped." }
        }
    end
  
    def sendRaw(msg)
      $log.debug('outgoing') { "Queued: #{msg}" }
      @sendq.push(msg)
      return msg
    end

    # Send a reply to a given message. Where to send it and how
    # to spit it up is determined within this method. Messages longer
    # than 400 characters will be split into separate messages. If
    # it can be split by words, it will be. If a word is too large, it
    # will be broken into pieces.
    # @param [IRCMessage] message The messasge to which we are replying. This is used to determine destination.
    # @param [String, Array<String>] replyStr A string or array of strings to be sent,
    # @param [Boolean] nickPrefix If true, prefix the message with the nick of the user to which we are replying.
    # @example In reply to a message from user Kabaka
    #   reply(message, "The answer is yes!") # Kabaka: The answer is yes!
    # @example In reply to a message from user Kabaka without the prefix
    #   reply(message, "The answer is no!", false) # The answer is no! 
    def reply(message, replyStr, nickPrefix = true)

      if replyStr.kind_of? Array
        replyStr.each { |replyItem|
          reply(message, replyItem, nickPrefix)
        }
        return
      end


      replyStr.to_s! unless replyStr.kind_of? String

      if replyStr.length > 400
        
        replyArr = replyStr.split(" ")
        buffer = ""
        bufferArr = Array.new

        replyArr.each { |word|

          if "#{buffer} #{word}".length < 400
            buffer += " #{word}"
          else
            bufferArr << buffer.strip unless buffer.empty?
            buffer.clear

            if word.length < 400
              buffer = word
            else
              word.each_char { |c|
                buffer += c
                if buffer.length == 400
                  bufferArr << buffer.strip
                  buffer.clear
                end
              }
            end
          end
        
        }

        bufferArr << buffer.strip unless buffer.empty?

        #replyStr = bufferArr
        reply(message, bufferArr, nickPrefix)
        return true

      end

      replyStr = "I tried to send you an empty reply. Oops!" if replyStr.length == 0

      replyStr = "#{message.speaker.nick}: #{replyStr}" if nickPrefix

      unless message.private?
        message.bot.sendPrivmsg(message.replyTo, replyStr)
      else
        message.bot.sendNotice(message.replyTo, replyStr)
      end
    end

  end

end # module IRC
