#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
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

require 'rss'
require 'htmlentities'


def initialize
  register_script "Periodically check RSS and ATOM feeds and post the new items to channels."

  register_command "rss", :cmd_rss,  1,  0, :half_op, "Manage the RSS/ATOM feeds for the current channel. Parameters: LIST|CHECK|CLEAR|ADD uri|DEL uri"

  register_event :em_started, :on_em_started
end

def on_em_started
  EM.add_periodic_timer(get_config(:interval, 1800)) { check_feeds }
end

def cmd_rss msg, params

  if msg.private?
    msg.reply "This command may only be used in channels."
    return
  end

  arr = params[0].split
  action = arr.shift.upcase
  arg = arr.shift

  case action
    when "LIST"

      feeds = get_data [msg.connection.name, msg.destination_canon], Array.new

      msg.send_notice msg.nick, "There are \02#{feeds.length}\02 feeds for #{msg.destination}"

      feeds.each do |feed|
        msg.send_notice msg.nick, feed[0]
      end

      msg.send_notice msg.nick, "End of list."

    when "CLEAR"

      delete_data [msg.connection.name, msg.destination_canon]

      msg.reply "The feed list has been cleared."

    when "ADD"
      
      unless arg =~ /\Ahttps?:\/\/.+\..+/
        msg.reply "That is not a URI I can handle. You must provide an HTTP URI."
        return
      end

      feeds = get_data [msg.connection.name, msg.destination_canon], Array.new

      feeds << [arg, ""]

      store_data [msg.connection.name, msg.destination_canon], feeds

      msg.reply "Feed added to the list for \02#{msg.destination}\02."

    when "DEL"

      feeds = get_data [msg.connection.name, msg.destination_canon], Array.new

      feed = feeds.select {|f| f[0] == arg}[0]

      if feed == nil or feed.empty?
        msg.reply("I don't have that feed in the list for #{msg.destination}. Please give the feed name exactly as appears in the output of LIST.")
        return
      end

      feeds.delete feed

      store_data [msg.connection.name, msg.destination_canon], feeds

      msg.reply "Feed deleted from the list for \02#{msg.destination}\02."

    when "CHECK"

      msg.reply "Checking feeds..."

      check_feeds

    else

      msg.reply "Unknown action. Parameters: LIST|CHECK|CLEAR|ADD uri|DEL uri"
  end

end

def check_feeds
  $log.debug("rss.check_feeds") { "Beginning check." }

  get_all_data.each do |key, val|

    network = key[0]
    channel = key[1]

    next unless Bot::Connections.has_key? network
    next unless Bot::Connections[network].channels.has_key? channel

    val.each do |feed|
      next if feed == nil
  
      $log.debug("rss.check_feeds") { "Checking %s for %s on %s" % [feed, channel, network] }

      Bot.http_get(URI(feed[0])) do |response|
        next unless response.status == 200

        rss = RSS::Parser.parse(response.content)

        send = false
        atom = rss.kind_of? RSS::Atom::Feed

        feed_title = sanitize(atom ? rss.title.to_s : rss.channel.title.to_s)

        items = rss.items[0..get_config(:max, 3).to_i-1].reverse

        items.each do |item|

          if item.title == feed[1]
            send = true

          elsif send or feed[1].empty?
            title = sanitize(item.title.to_s)

            link = sanitize(atom ? item.links.select {|l| l.rel == "alternate"}[0].href.to_s : item.link.to_s)

            Bot::Connections[network].raw "PRIVMSG #{channel} :\02[#{feed_title}]\02 #{title} :: #{link}"

          end

        end

        # update the last read title

        feed[1] = items.last.title.to_s
      end
    end
  end

  $log.debug("rss.check_feeds") { "Done checking feeds." }
end

def sanitize(str)
  return HTMLEntities.new.decode str.gsub(/[\s]+/, " ").gsub(/<\/?[^>]+>/, "")
end

