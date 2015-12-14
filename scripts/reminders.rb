#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
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

register 'Schedule delayed reminders.'

event :periodic do
  run_reminders
end

command 'remind', 'Schedule a relayed reminder. The delay is specified by a string where x1y1x2y2..xnyn where x is a number and y is a time unit (any of: s m h d w y) Syntax: delay message' do
  channel! and argc! 2

  time = Time.parse_duration @params.shift

  if time.to_i <= Time.now.to_i
    raise 'reminders must be set for a time in the future'
  end

  reminder = {
    time: time.to_i,
    creator: @msg.nick,
    message: @params.shift
  }

  network_reminders = get_data @connection.name, {}

  network_reminders[@msg.destination] ||= []
  network_reminders[@msg.destination] << reminder

  store_data @connection.name, network_reminders

  reply "Reminder scheduled for #{time}"
end

helpers do
  def run_reminders
    now = Time.now.to_i

    data = get_all_data

    data.reject! do |network, destinations|
      unless Bot::Connections.has_key? network
        $log.warn('Script.reminders') { "Skipping reminders for offline network #{network}" }
        next
      end

      destinations.reject! do |destination, reminders|
        reminders.reject! do |reminder|
          next if now < reminder[:time]

          send_reminder network, destination,
            reminder[:creator], reminder[:message]
        end

        reminders.empty?
      end

      destinations.empty?
    end

    store_all_data data
  end

  def send_reminder network, destination, nick, message
    connection = Bot::Connections[network]

    unless connection.channels.has_key? connection.canonize(destination)
      $log.warn('Script.reminders') { "Skipping reminder for parted channel #{destination} on #{network}" }
      return false
    end

    Bot::Connections[network].send_privmsg destination,
      "\02Reminder for #{nick}:\02 #{message}"

    true
  end
end

# vim: set tabstop=2 expandtab:
