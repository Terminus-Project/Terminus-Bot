
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

def initialize
  register_script("Network utility script, including ping and other tools.")

  register_command("icmp",   :cmd_icmp,  1,  0, nil, "Check if the given host is up and answering pings.")
  register_command("mtr",    :cmd_mtr,   1,  0, nil, "Show data about the route to the given host.")
  register_command("icmp6",  :cmd_icmp6, 1,  0, nil, "Check if the given IPv6 host is up and answering pings.")
  register_command("mtr6",   :cmd_mtr6,  1,  0, nil, "Show data about the route to the given IPv6 host.")
end

def cmd_icmp(msg, params)
  host = params[0].chomp

  if validate_host_name(host)
    EM.defer(proc { do_ping(msg, host) })
  else
    msg.reply("Invalid host name.")
  end
end

def cmd_icmp6(msg, params)
  host = params[0].chomp

  if validate_host_name(host)
    EM.defer(proc { do_ping(msg, host, true) })
  else
    msg.reply("Invalid host name.")
  end
end

def do_ping(msg, host, v6 = false)
  EM.system("ping#{v6 ? "6" : ""} -q -c 5 #{host}") do |o,s|

    if s.exitstatus == 2
      msg.reply("Invalid host name.")
    elsif s.exitstatus == 0 or s.exitstatus == 1
      buf = Array.new

      o.each_line do |l|
        buf << l.chomp if l =~ /^[0-9]+ packets transmitted/ or l.start_with? "rtt"
      end

      msg.reply(buf.join(" :: "))
    else
      msg.reply("There was an unknown problem pinging that host.")
    end

  end
end



def cmd_mtr(msg, params)
  host = params[0].chomp

  if validate_host_name(host)
    EM.defer(proc { do_mtr(msg, host) })
  else
    msg.reply("Invalid host name.")
  end
end

def cmd_mtr6(msg, params)
  host = params[0].chomp

  if validate_host_name(host)
    EM.defer(proc { do_mtr(msg, host, true) })
  else
    msg.reply("Invalid host name.")
  end
end

def do_mtr(msg, host, v6 = false)
  EM.system("mtr -#{v6 ? "6" : "4"} -c 1 -r #{host}") do |o,s|
    if s.exitstatus == 1
      msg.reply("INvaliud host name.")
    else
      hops = 0
      up = 0
      avg = 0
      longest = 0

      first = true

      o.each_line do |l|

        # first line is a header
        if first
          first = false
          next
        end

        hops += 1

        arr = l.split

        if arr[2] == "0.0%"
          up += 1
        end

        time = arr[5].to_f

        avg += time

        longest = time if time > longest
      end

      msg.reply("\02Hops:\02 #{hops} \02Up:\02 #{up} \02Down:\02 #{hops-up} \02Average Reply Time (ms):\02 #{sprintf("%.1f", avg/hops)} \02Longest Reply Time (ms):\02 #{longest}")
    end
  end
end

def validate_host_name(host)
  host =~ /\A[^-][\w.:-]+\Z/
end
