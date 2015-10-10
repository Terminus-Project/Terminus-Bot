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

register 'Network utility script, including ping and other tools.'

command 'icmp', 'Check if the given host is up and answering pings.' do
  argc! 1

  host = @params.first.chomp

  unless is_valid_host_name? host
    reply "Invalid host name."
    next
  end

  #EM.defer(proc { do_ping host })
  do_ping host
end

command 'icmp6', 'Check if the given IPv6 host is up and answering pings.' do
  argc! 1

  host = @params.first.chomp

  unless is_valid_host_name? host
    reply "Invalid host name."
    next
  end

  #EM.defer(proc { do_ping host, true })
  do_ping host, true
end

command 'mtr', 'Show data about the route to the given host.' do
  argc! 1

  host = @params.first.chomp

  unless is_valid_host_name? host
    reply "Invalid host name."
    next
  end

  EM.defer(proc { do_mtr host })
end

command 'mtr6', 'Show data about the route to the given IPv6 host.' do
  argc! 1

  host = @params.first.chomp

  unless is_valid_host_name? host
    reply "Invalid host name."
    return
  end

  EM.defer(proc { do_mtr host, true })
end

helpers do
  def do_mtr host, v6 = false
    EM.system("mtr -#{v6 ? "6" : "4"} -c 1 -r #{host} 2>/dev/null") do |o, s|

      case s.exitstatus
      when 1
        reply "Could not perform MTR for that host due to network or DNS errors."
      when 0
        hops, up, avg, longest = 0, 0, 0, 0

        o.each_line.each_with_index do |l, i|
          next if i.zero? # skip header

          hops += 1

          arr = l.split

          up += 1 if arr[2] == "0.0%"

          time = arr[5].to_f
          avg += time

          longest = time if time > longest
        end

        if hops.zero?
          reply "Unable to perform MTR for this host."
          next
        end

        data = {
          'Hops'                    => hops,
          'Up'                      => up,
          'Down'                    => (hops - up),
          'Average Reply Time (ms)' => sprintf("%.1f", avg/hops),
          'Longest Reply Time (ms)' => longest
        }

        reply data
      else
        reply "Unable to perform MTR for this host."
      end

    end
  end

  # must return false if input is not safe for command line
  def is_valid_host_name? host
    host =~ /\A[^-][\w.:-]+\Z/
  end

  def do_ping host, v6 = false
    EM.system("ping#{"6" if v6} -q -w 5 -c 5 #{host}") do |o, s|

      case s.exitstatus
      when 2
        reply "Could not ping that host due to network or DNS errors."
      when 0
        buf = []

        o.each_line do |l|
          if l =~ /^[0-9]+ packets transmitted/ or l.start_with? "rtt"
            buf << l.chomp
          end
        end

        reply buf.join(" :: ")
      else
        reply "There was an unknown problem pinging that host."
      end

    end
  end

end

# vim: set tabstop=2 expandtab:
