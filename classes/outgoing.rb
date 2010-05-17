
  require 'thread'
  
  @@messageQueue = Queue.new
    Thread.new {
      while true
        msg = @@messageQueue.pop
        puts "*** SENDER: #{msg}"
        $socket.puts(msg)
        sleep MESSAGEDELAY
      end
    }

  def sendMessage(msg)
    @@messageQueue.push(msg)
  end
