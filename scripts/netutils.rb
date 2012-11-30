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

def initialize
  register_script "Network utility script, including ping and other tools."

  register_command "icmp",  :cmd_icmp,  1,  0, nil, "Check if the given host is up and answering pings."
  register_command "mtr",   :cmd_mtr,   1,  0, nil, "Show data about the route to the given host."
  register_command "icmp6", :cmd_icmp6, 1,  0, nil, "Check if the given IPv6 host is up and answering pings."
  register_command "mtr6",  :cmd_mtr6,  1,  0, nil, "Show data about the route to the given IPv6 host."
end

def cmd_icmp msg, params
  host = params[0].chomp

  unless is_valid_host_name? host
    msg.reply "Invalid host name."
    return
  end
  
  #EM.defer(proc { do_ping msg, host })
  do_ping msg, host
end

def cmd_icmp6 msg, params
  host = params[0].chomp

  unless is_valid_host_name? host
    msg.reply "Invalid host name."
    return
  end

  EM.defer(proc { do_ping msg, host, true })
end

def do_ping msg, host, v6 = false
  EM.system("ping#{"6" if v6} -q -w 5 -c 5 #{host}") do |o, s|

    case s.exitstatus
    when 2
      msg.reply "Could not ping that host due to network or DNS errors."
    when 0
      buf = []

      o.each_line do |l|
        if l =~ /^[0-9]+ packets transmitted/ or l.start_with? "rtt"
          buf << l.chomp
        end
      end

      msg.reply buf.join(" :: ")
    else
      msg.reply "There was an unknown problem pinging that host."
    end

  end
end



def cmd_mtr msg, params
  host = params[0].chomp

  unless is_valid_host_name? host
    msg.reply "Invalid host name."
    return
  end

  EM.defer(proc { do_mtr msg, host })
end

def cmd_mtr6 msg, params
  host = params[0].chomp

  unless is_valid_host_name? host
    msg.reply "Invalid host name."
    return
  end
    
  EM.defer(proc { do_mtr msg, host, true })
end

def do_mtr msg, host, v6 = false
  EM.system("mtr -#{v6 ? "6" : "4"} -c 1 -r #{host} 2>/dev/null") do |o, s|

    case s.exitstatus
    when 1
      msg.reply "Could not perform MTR for that host due to network or DNS errors."
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
        msg.reply "Unable to perform MTR for this host."
        next
      end

      output = [
        "\02Hops:\02 #{hops}",
        "\02Up:\02 #{up}",
        "\02Down:\02 #{hops - up}",
        "\02Average Reply Time (ms):\02 #{sprintf("%.1f", avg/hops)}",
        "\02Longest Reply Time (ms):\02 #{longest}"
      ].join(' ')

      msg.reply output
    else
      msg.reply "Unable to perform MTR for this host."
    end

  end
end

# must return false if input is not safe for command line
def is_valid_host_name? host
  host =~ /\A[^-][\w.:-]+\Z/
end

