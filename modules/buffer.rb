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
  
  MODULE_LOADED_BUFFER  = true
  MODULE_VERSION_BUFFER = 0.1

  class BufferManager < Hash

    def initialize
      Events.register(self, :"001",   :on_registered)
      Events.register(self, :JOIN,    :on_join)
      Events.register(self, :PART,    :on_part)
      Events.register(self, :PRIVMSG, :record_message)
      Events.register(self, :NOTICE,  :record_message)
    end

    def on_registered(msg)
      self[msg.connection.name] ||= {}
    end

    def on_join(msg)
      self[msg.connection.name][msg.destination_canon] ||= []
    end

    def on_part(msg)
      self[msg.connection.name].delete(msg.destination_canon)
    end

    def record_message(msg)
      return if msg.private?

      if msg.type == :PRIVMSG

        if msg.text =~ /\01ACTION (.+)\01/
          text = $1
          type = :ACTION
        else
          text = msg.text
          type = msg.type
        end

      else
        text = msg.text
        type = msg.type
      end

      self[msg.connection.name][msg.destination_canon] << (:type => type,
                                                           :text => text,
                                                           :nick => msg.nick)
     
      # TODO: This is nasty. I am using a loop here because we might be
      # rehashed with a smaller value and have to shift it down to size. There
      # are better ways of doing this.
      while self[msg.connection.name][msg.destination_canon].length > Config[:modules][:buffer][:max_size]
        self[msg.connection.name][msg.destination_canon].shift
      end
    end

  end

  Buffer = BufferManager.new

end
