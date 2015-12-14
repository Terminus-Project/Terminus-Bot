#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2015 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'Modify and query the script flag table.'

# TODO: Allow channel operators to change flags for their own channels.

command 'enable', 'Enable scripts in the given server and channel. Wildcards are supported. Parameters: server channel scripts' do
  level! 4 and argc! 3

  enabled = Bot::Flags.enable @params[0], @connection.canonize(@params[1]), @params[2]

  reply "Enabled \02#{enabled}\02."
end


command 'disable', 'Disable scripts in the given server and channel. Wildcards are supported. Parameters: server channel scripts' do
  level! 4 and argc! 3

  enabled = Bot::Flags.disable @params[0], @connection.canonize(@params[1]), @params[2]

  reply "Disabled \02#{enabled}\02."
end


command 'flags', 'View flags for the given servers, channels, and scripts. Wildcards are supported. Parameters: server channel scripts' do
  argc! 3

  enabled, disabled, default = [], [], []

  Bot::Flags.each_pair do |server, channels|
    next unless server.wildcard_match @params[0]

    channels.each_pair do |channel, scripts|
      next unless channel.wildcard_match @params[1]

      scripts.each_pair do |script, flag|
        next unless script.wildcard_match @params[2]

        case flag
        when -1
          disabled << script
        when 1
          enabled << script
        else
          default << script
        end

      end
    end
  end

  disabled.uniq!
  enabled.uniq!
  default.uniq!

  buf = ""

  buf << "\02Enabled (#{enabled.length}):\02 #{enabled.join(", ")}" unless enabled.empty?
  buf << " \02Disabled (#{disabled.length}):\02 #{disabled.join(", ")}" unless disabled.empty?
  buf << " \02Default (#{default.length}):\02 #{default.join(", ")}" unless default.empty?

  reply buf.empty? ? "No flags set." : buf
end

# vim: set tabstop=2 expandtab:
