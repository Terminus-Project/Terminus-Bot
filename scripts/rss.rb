
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'rss'
require 'open-uri'
require 'htmlentities'


def initialize
  register_script("Periodically check RSS and ATOM feeds and post the new items to channels.")

  register_command("rss", :cmd_rss,  1,  3, "Manage the RSS/ATOM feeds for the current channel. Parameters: LIST|CHECK|CLEAR|ADD uri|DEL uri")

  EM.add_periodic_timer(1800) { check_feeds }
end

def cmd_rss(msg, params)

  if msg.private?
    msg.reply("This command may only be used in channels.")
    return
  end

  arr = params[0].split
  action = arr.shift.upcase
  arg = arr.shift

  case action
    when "LIST"

      feeds = get_data([msg.connection.name, msg.destination], Array.new)

      msg.send_notice(msg.nick, "There are \02#{feeds.length}\02 feeds for #{msg.destination}")

      feeds.each do |feed|
        msg.send_notice(msg.nick, feed[0])
      end

      msg.send_notice(msg.nick, "End of list.")

    when "CLEAR"

      delete_data([msg.connection.name, msg.destination])

      msg.reply("The feed list has been cleared.")

    when "ADD"
      
      unless arg =~ /\Ahttps?:\/\/.+\..+/
        msg.reply("That is not a URI I can handle. You must provide an HTTP URI.")
        return
      end

      feeds = get_data([msg.connection.name, msg.destination], Array.new)

      feeds << [arg, ""]

      store_data([msg.connection.name, msg.destination], feeds)

      msg.reply("Feed added to the list for \02#{msg.destination}\02.")

    when "DEL"

      feeds = get_data([msg.connection.name, msg.destination], Array.new)

      feed = feeds.select {|f| f[0] == arg}[0]

      if feed == nil or feed.empty?
        msg.reply("I don't have that feed in the list for #{msg.destination}. Please give the feed name exactly as appears in the output of LIST.")
        return
      end

      feeds.delete(feed)

      store_data([msg.connection.name, msg.destination], feeds)

      msg.reply("Feed deleted from the list for \02#{msg.destination}\02.")

    when "CHECK"

      msg.reply("Checking feeds...")

      check_feeds

    else

      msg.reply("Unknown action. Parameters: LIST|CHECK|CLEAR|ADD uri|DEL uri")
  end

end

def check_feeds
  $log.debug("rss.check_feeds") { "Beginning check." }

  get_all_data.each do |key, val|

    network = key[0]
    channel = key[1]

    next unless $bot.connection.has_key? network
    next unless $bot.connection[network].channels.has_key? channel

    val.each do |feed|
      rss = get_feed(feed[0])
      next if feed == nil

      send = false
      atom = rss.kind_of? RSS::Atom::Feed

      feed_title = sanitize(atom ? rss.title.to_s : rss.channel.title.to_s)

      items = rss.items[0..get_config("max", 3).to_i-1].reverse

      items.each do |item|

        if item.title == feed[1]
          send = true

        elsif send or feed[1].empty?
          title = sanitize(item.title.to_s)

          link = sanitize(atom ? item.links.select {|l| l.rel == "alternate"}[0].href.to_s : item.link.to_s)

          $bot.connections[network].raw("PRIVMSG #{channel} :\02[#{feed_title}]\02 #{title} :: #{link}")

        end

      end

      # update the last read title

      feed[1] = items.last.title.to_s
    end
  end

  $log.debug("rss.check_feeds") { "Done checking feeds." }
end

def get_feed(uri)
  open(uri) do |rss|
    return RSS::Parser.parse(rss)
  end
end

def sanitize(str)
  return HTMLEntities.new.decode(str.gsub(/[\s]+/, " ").gsub(/<\/?[^>]+>/, ""))
end
