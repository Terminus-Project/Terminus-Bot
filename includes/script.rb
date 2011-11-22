
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
  class Scripts

    def initialize
      $log.info("scripts.initilize") { "Loading scripts." }

      @scripts = Hash.new

      Dir.glob("scripts/*.rb").each do |file|

        $log.debug("scripts.initilize") { "Loading #{file}" }
        load_file(file)

      end
    end

    def load_file(filename)
      name = filename.match("scripts/(.+).rb")[1]

      $log.debug("scripts.load") { "Script file name: #{filename}" }

      script = "class Script_#{name} < Script \n #{IO.read(filename)} \n end \n Script_#{name}.new"
      
      if @scripts.has_key? name
        throw "Attempted to load script that is already loaded."
      end

      @scripts[name] = eval(script, nil, filename, 0)
    end

    def reload(name)
      unless @scripts.has_key? name
        throw "Cannot reload: No such script #{name}"
      end

      filename = "scripts/#{name}.rb"

      unless File.exists? filename
        throw "Script file for #{name} does not exist (#{filename})."
      end

      @scripts[name].die if @scripts[name].respond_to? "die"

      @scripts.delete(name)

      load_file(filename)
    end

    def unload(name)
      unless @scripts.has_key? name
        throw "Cannot unload: No such script #{name}"
      end

      @scripts[name].die if @scripts[name].respond_to? "die"

      @scripts.delete(name)
    end
  end

  class Script

    def method_missing(name, *args, &block)
      if $bot.respond_to? name
        $bot.send(name, *args, &block)
      else
        $log.error("Script.method_missing") { "Attempted to call nonexistent method #{name}" }
        throw NoMethodError.new("#{my_name} attempted to call a nonexistent method #{name}", name, args)
      end
    end

    def register_event(*args)
      $bot.events.create(self, *args)
    end

    def register_command(*args)
      $bot.register_command(self, *args)
    end

    def register_script(*args)
      $bot.register_script(my_short_name, *args)
    end


    def unregister_commands
      $bot.unregister_commands(self)
    end

    def unregister_events
      $bot.unregister_events(self)
    end

    def unregister_script
      $bot.unregister_script(my_short_name)
    end


    def my_name 
      self.class.name.split("::").last
    end

    def my_short_name 
      self.class.name.split("::").last.split("_").last
    end


    def get_config(key, default)
      if $bot.config.has_key? my_short_name
        if $bot.config[my_short_name].has_key? key
          return $bot.config[my_short_name][key]
        end
      end

      return default
    end

    def init_data
      unless $bot.database.has_key? my_name
        $bot.database[my_name] = Hash.new
      end
    end

    def get_data(key, default = nil)
      init_data

      if $bot.database[my_name].has_key? key
        return $bot.database[my_name][key]
      else
        return default
      end
    end

    def default_data(key, value)
      init_data

      unless $bot.database[my_name].has_key? key
        $bot.database[my_name][key] = value
      end
    end

    def store_data(key, value)
      init_data

      $bot.database[my_name][key] = value
    end

    def delete_data(key)
      init_data

      if $bot.database[my_name].has_key? key
        $bot.database[my_name].delete(key)
      end
    end

    def to_str
      my_short_name
    end
  end
end
