#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2013 Kyle Johnson <kyle@vacantminded.com>
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

# Dummy canonization class for {CanonizedHash}. Only works for {String} keys by using
# String#upcase.
class DummyCanonizer
  def self.canonize str
    str.upcase
  end
end

# Hash implementation that can use an external canonizer for keys.
class CanonizedHash < Hash

  # Create a new CanonizedHash object.
  #
  # Use as a normal {Hash}, but include a object in the declaration that has a
  # `canonizer` function. All keys will be passed to the canonizer before use.
  #
  # @example
  #   channels = CanonizedHash.new @connection
  #   channels['#terminus-bot'] = 'bar'
  #   channels                            # => {"#TERMINUS-BOT" => "bar"}
  #
  # @param canonizer [Object] instance of a class which has a canonize function
  def initialize canonizer = DummyCanonizer, *args
    @canonizer = canonizer
    super(*args)
  end

  def [] key
    super(@canonizer.canonize key)
  end

  def []= key, value
    super(@canonizer.canonize(key), value)
  end

  def delete key
    super(@canonizer.canonize key)
  end

  def has_key? key
    super(@canonizer.canonize key)
  end

  def include? key
    super(@canonizer.canonize key)
  end

  def default key
    super(@canonizer.canonize key)
  end

  def fetch key, *args
    super(@canonizer.canonize(key), *args)
  end

  def key? key
    super(@canonizer.canonize key)
  end

  def member? key
    super(@canonizer.canonize key)
  end

  def store key, value
    super(@canonizer.canonize(key), value)
  end

  def values_at *keys
    keys.map! {|k| @canonizer.canonize k}
    super(*keys)
  end
end
