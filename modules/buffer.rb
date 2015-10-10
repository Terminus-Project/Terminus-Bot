#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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
      Events.create :PART,    self, :on_part
      Events.create :PRIVMSG, self, :record_message
      Events.create :NOTICE,  self, :record_message

      super
    end

    def on_part msg
      return unless msg.me?
      self[msg.connection.name].delete msg.destination
    end

    def record_message msg
      return if msg.query?

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

      self[msg.connection.name] ||= CanonizedHash.new(msg.connection)
      self[msg.connection.name][msg.destination] ||= []

      self[msg.connection.name][msg.destination] << {:type => type,
                                                     :text => text,
                                                     :nick => msg.nick}

      max = Conf[:modules][:buffer][:max_size] rescue 100

      # TODO: This is nasty. I am using a loop here because we might be
      # rehashed with a smaller value and have to shift it down to size. There
      # are better ways of doing this.
      while self[msg.connection.name][msg.destination].length > (Conf[:modules][:buffer][:max_size].to_i rescue 100)
        self[msg.connection.name][msg.destination].shift
      end
    end

  end

  Buffer ||= BufferManager.new

end
# vim: set tabstop=2 expandtab:
