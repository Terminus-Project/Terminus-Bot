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
  require 'thread'
  
  @@messageQueue = Queue.new
    Thread.new {
      $log.debug('outgoing') { "Thread started." }
      while true
        msg = @@messageQueue.pop
        $log.debug('outgoing') { "Sent: #{msg}" }
        $socket.puts(msg)
        sleep $config["Core"]["Bot"]["MessageDelay"]
      end
      $log.debug('outgoing') { "Thread stopped." }
    }

  def sendRaw(msg)
    @@messageQueue.push(msg)
  end

  def reply(message, replyStr, nickPrefix = false)
    if replyStr.length > 400
      nextStr = replyStr.slice!(0..399)
      reply(message, nextStr, nickPrefix)
    end

    replyStr = "#{message.speaker.nick}: #{replyStr}" if nickPrefix

    if message.type == CHANNEL
      sendPrivmsg(message.replyTo, replyStr)
    else
      sendNotice(message.replyTo, replyStr)
    end
  end

  def sendPrivmsg(destination, message)
    sendRaw("PRIVMSG #{destination} :#{message}")
  end

  def sendNotice(destination, message)
    sendRaw("NOTICE #{destination} :#{message}")
  end

  def sendMode(target, mode, parameters = "")
    sendRaw("MODE #{target}#{" #{parameters}" unless parameters.empty?}")
  end
