
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

  def sendMessage(msg)
    @@messageQueue.push(msg)
  end
