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

# TODO: Make this a class!

  require 'thread'
 
  # Stick messages here before sending them off. This will be in a class, soon!
  @@messageQueue = Queue.new
    Thread.new {
      $log.debug('outgoing') { "Thread started." }
      while true
        msg = @@messageQueue.pop
        $log.debug('outgoing') { "Sent: #{msg}" }
        $socket.puts(msg)
        sleep $bot.config["Throttle"]
      end
      $log.debug('outgoing') { "Thread stopped." }
    }

  def sendRaw(msg)
    @@messageQueue.push(msg)
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
      sendPrivmsg(message.replyTo, replyStr)
    else
      sendNotice(message.replyTo, replyStr)
    end
  end

  # Send a message to a channel or user.
  # @param [String] destination The user or channel to which the message will be sent
  # @param [String] message The message to send.
  # @example Say "hi!" to channel #terminus-bot
  #   sendPrivmsg("#terminus-bot", "Hi!")
  # @example Greet a user in private.
  #   sendPrivmsg("Kabaka", "Hello, Kabaka!")
  def sendPrivmsg(destination, message)
    sendRaw("PRIVMSG #{destination} :#{message}")
  end

  # Send a notice to a channel or user (or whatever else the server permits).
  # @param [String] destination The user or channel to which the message will be sent
  # @param [String] message The message to send.
  # @example Say "hi!" to channel #terminus-bot
  #   sendNotice("#terminus-bot", "Hi!")
  # @example Greet a user in private.
  #   sendNotice("Kabaka", "Hello, Kabaka!")
  def sendNotice(destination, message)
    sendRaw("NOTICE #{destination} :#{message}")
  end

  # Send a mode change to the server with optional parameters.
  # @param [String] target The target for the mode change. This will be a channel or user (if a user, it will probably need to be the bot).
  # @param [String] mode The mode to send, such as +v if the target is a channel.
  # @param [String] parameters Optional parameters for the mode change. This is for things like voice targets if your mode is +v and target is a channel.
  def sendMode(target, mode, parameters = "")
    sendRaw("MODE #{target} #{mode}#{" #{parameters}" unless parameters.empty?}")
  end

  # Send a CTCP request. This is the same as a PRIVMSG, but wrapped in
  # the CTCP markers (character code 1).
  # @param [String] destination The user or channel to which this should be sent. CTCPs should generally be sent to a user!
  # @param [String] message The contents of the CTCP request, such as VERSION.
  def sendCTCP(destination, message)
    sendRaw("PRIVMSG #{destination} :#{1.chr}#{message}#{1.chr}")
  end
