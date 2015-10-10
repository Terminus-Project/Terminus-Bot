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

module Bot

  class Configuration < Hash

    # Create a new configuration object and immediately read the configuration
    # file.
    #
    # @see Configuration#read_config
    def initialize
      read_config
    end

    # Read the configuration file according to command line args.
    #
    # The configuration file is expected to be in a nested block format. Syntax
    # is presently very strict.
    #
    #     block_name ={
    #       # ...
    #     }
    #
    #     setting = value
    #
    #     #comment
    #
    # @raise if file does not exist
    def read_config
      file_name = $opts[:config_file]

      raise "No Config File" unless File.exists? file_name

      $log.info("Configuration.read_config") { "Loading the configuration file." }

      fi = File.open file_name, 'r'

      parents, line_number = [], 0

      current = self

      # Read in the whole file, skipping comments and stuff.
      while line = fi.gets
        line.strip!
        line_number += 1

        # Skip comments and empty lines.
        next if line[0] == "#" or line.empty?

        if line == "}"
          raise "Unexpected } on line #{line_number}" if parents.empty?

          current = parents.pop

          next
        end

        unless line.include? "="
          key, value = line.strip, nil

        else
          key, value = line.split "=", 2

          key.strip!
          value.strip!

        end

        key = key.to_sym

        if value == "{"

          if current.has_key? key
            $log.warn("Configuration.read_config") { "Duplicate configuration block #{key} on line #{line_number}" }
          else
            current[key] = {}
          end

          parents << current
          current = current[key]

          next
        end

        if current.has_key? key
          $log.warn("Configuration.read_config") { "Duplicate configuration option #{key} on line #{line_number}" }
        end

        # Handle a few data types.

        unless value == nil

          if value =~ /\A\d+\Z/
            value = value.to_i

          elsif value =~ /\A\d+\.\d+\Z/
            value = value.to_f

          elsif value.casecmp("true").zero?
            value = true

          elsif value.casecmp("false").zero?
            value = false

          end

        end

        current[key] = value
      end

      $log.debug("Configuration.read_config") { "Done loading the configuration file." }

      fi.close
    end

    # TODO: Rehashes are broken. The just overwrite existing values and leave
    # values that were removed. Maybe extending Hash is not ideal.


  end

  Conf ||= Configuration.new
end
# vim: set tabstop=2 expandtab:
