
  require 'thread'
  
  @@messageQueue = Queue.new
    Thread.new {
      puts "*** SENDER THREAD STARTED ***"
      while true
        msg = @@messageQueue.pop
        puts "*** SENDER: #{msg}"
        $socket.puts(msg)
        sleep 0.1
      end
      puts "*** SENDER THREAD EXITING ***"
    }

  def sendMessage(msg)
    @@messageQueue.push(msg)
  end
