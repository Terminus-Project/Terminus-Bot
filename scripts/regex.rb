#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco,
# David Farrell <shokku.ra@gmail.com> (http://terminus-bot.net/)
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

need_module! 'buffer'

require 'timeout'

register 'Show corrected text with s/regex/replacement/ is used and allow searching with g/regex/.'

event :PRIVMSG do
  next if query?

  match = @msg.text.match(/^(?<action>(s|g))\/(?<search>((\\\\)|(\\\/)|.)+?)\/(?<replace>((\\\\)|(\\\/)|.)+?)(\/(?<flags>.*))?$/)

  if match
    next unless Buffer.has_key? @connection.name
    next unless Buffer[@connection.name].has_key? @msg.destination_canon

    case match[:action]
    when 'g'
      grep match
    when 's'
      substitute match
    end

    next
  end
end

helpers do
  def grep match
    Timeout::timeout(get_config(:run_time, 2).to_i) do
      # match[:replace] is flags because whatever
      search, flags, opts = match[:search], match[:replace], Regexp::EXTENDED

      opts |= Regexp::IGNORECASE if flags and flags.include? 'i'

      search = Regexp.new match[:search].gsub(/\s/, '\s'), opts

      Buffer[@connection.name][@msg.destination_canon].reverse.each do |message|
        next if message[:text].match(/^[rsg]{1}\/(.+?)\/(.*?)(\/.*)?$/)

        if search.match message[:text]
          reply_with_match message[:type], message[:nick], message[:text]

          return
        end

      end
    end
  end

  def substitute match
    Timeout::timeout(get_config(:run_time, 2).to_i) do
      replace, flags, opts = match[:replace], match[:flags], Regexp::EXTENDED
      replace = replace.gsub(/(?<!\\)\\\//, "/")

      opts |= Regexp::IGNORECASE if flags and flags.include? 'i'

      search = Regexp.new match[:search].gsub(/\s/, '\s'), opts

      $log.debug('regex') { search }

      Buffer[@connection.name][@msg.destination_canon].reverse.each do |message|
        next if message[:text].match(/^[rsg]{1}\/(.+?)\/(.*?)(\/.*)?$/)

        if search.match message[:text]
          new_msg = ((flags and flags.include?('g')) ? message[:text].gsub(search, replace) : message[:text].sub(search, replace) )

          reply_with_match message[:type], message[:nick], new_msg

          return
        end

      end
    end
  end

  def reply_with_match type, nick, message
    case type
    when :ACTION
      reply "* #{nick} #{message}", false
    when :PRIVMSG
      reply "<#{nick}> #{message}", false
    when :NOTICE
      reply "-#{nick}- #{message}", false
    end
  end
end

# vim: set tabstop=2 expandtab:
