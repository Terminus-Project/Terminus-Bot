
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2010 Terminus-Bot Development Team
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


module Terminus_Bot
  class Configuration

    attr :config

    FILE_NAME = "terminus-bot.conf"

    def initialize
      read_config
    end


    def read_config
      unless File.exists? FILE_NAME
        throw "No Config File"
      end

      $log.info("Configuration.read_config") { "Loading the configuration file." }

      @config = Hash.new

      fi = File.open(FILE_NAME, "r")

      section = ""

      while line = fi.gets
        line.strip!

        if line[0] == "#" or line.empty?
          next
        end

        if line =~ /\[(.+)\]/
          section = $1.strip

          unless @config.has_key? section
            @config[section] = Hash.new
            $log.debug("Configuration.read_config") { "New config section: #{section}" }
          end

        elsif line =~ /\A(.+)=(.+)\Z/
          
          if section.empty?
            throw "Congifuration before section declaration."
          end

          @config[section][$1.strip] = $2.strip

        end

      end

      $log.debug("Configuration.read_config") { "Done loading the configuration file." }

      fi.close
    end

    def method_missing(name, *args, &block)
      if @config.respond_to? name
        @config.send(name, *args, &block)
      else
        $log.error("Configuration.method_missing") { "Attempted to call nonexistent method #{name}" }
        throw NoMethodError.new("Attempted to call a nonexistent method", name, args)
      end
    end
  end
end

