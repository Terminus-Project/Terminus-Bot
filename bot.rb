#!/usr/bin/ruby

require 'socket'

class TerminusBot

  def initialize(server, port, channel)
    @doneConnecting = false

    @channel = channel
    $socket = TCPSocket.open(server, port)
    say "NICK Terminus-Bot"
    say "USER Terminus 0 * TerminusBot"
  end

  def say(msg)
    $socket.puts(msg)
  end

  def say_to_chan(msg)
    sendMessage("PRIVMSG ##{@channel} :#{msg}")
  end

  def run
    until $socket.eof? do
      msg = $socket.gets
      #puts msg

      # go ahead and handle server PING first
      if msg.match(/^PING :(.*)$/)
        say "PONG #{$~[1]}"
        next
      end
      
      msgArr = msg.match(/^:?(.*)$/)[1].split(/ /)

      case msgArr[1]
        when "PRIVMSG"
          content = msg.match(/PRIVMSG .* :(.*)$/)[1]
          message = IRCMessage.new(msgArr[2], content, msgArr[0])

          # echo it!
          puts "[#{message.timestamp}] <#{message.speaker.nick}:#{message.origin}> #{message.message}"
          attemptHook(message.msgArr[0], message)
        when "NOTICE"
          content = msg.match(/NOTICE .* :(.*)$/)[1]
          message = IRCMessage.new(msgArr[2], content, msgArr[0])

          # echo it!
          puts "[#{message.timestamp}] --#{message.speaker.nick}:#{message.origin}-- #{message.message}"

        when "376" #end of motd
          say "JOIN ##{@channel}"
          say_to_chan "#{1.chr}ACTION is done connecting.#{1.chr}"
          @doneConnecting = true
          
        when "422" #motd not found
          say "JOIN ##{@channel}"
          say_to_chan "#{1.chr}ACTION is done connecting.#{1.chr}"
          @doneConnecting = true

	#else
        #  puts "Unknown message type: #{msg}"
      end

      next
    end
  end

  def quit(quitMessage = "Terminus-Bot: Terminating.")
    say 'QUIT ' + quitMessage
  end

  def attemptHook(cmd, msg)
    if cmd.match(/\A#{CMDPREFIX}(.*)/)
      cmd = $~[1]
      
      $modules.each do |m|
          m.send("cmd_#{cmd}",msg) unless not m.respond_to?("cmd_#{cmd}")
         puts "ATTEMPT HOOK #{m} -> cmd_#{cmd}"
      end
    end
  end
end

puts "Loading configuration..."
load "conf.rb"

puts "Loading bot core..."
Dir.foreach("classes") { |f| load "./classes/#{f}" unless f.match(/^\.+$/) }

puts "Loading modules..."

$modules = Array.new()

Dir.foreach("modules") { |f|
  unless f.match(/^\.+$/)
    load "./modules/#{f}"
  end
}

puts "Done. Establishing IRC connection..."
bot = TerminusBot.new("irc.sinsira.net", 6667, 'terminus-bot')

puts "Terminus-Bot started! Running..."

trap("INT"){ bot.quit }

bot.run
