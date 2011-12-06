
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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

    # Load all the scripts in the scripts directory.
    def initialize
      $log.info("scripts.initilize") { "Loading scripts." }

      @scripts = Hash.new

      unless Dir.exists? "scripts"
        throw "Scripts directory does not exist."
      end

      noload = $bot.config['core']['noload']

      noload = noload.split unless noload == nil

      Dir.glob("scripts/*.rb").each do |file|

        unless noload == nil
          # I realize we are pulling the name out twice. Deal with it.
          next if noload.include? file.match("scripts/(.+).rb")[1]
        end

        $log.debug("scripts.initilize") { "Loading #{file}" }
        load_file(file)

      end
    end

    # Run the die functions on all scripts.
    def die
      @scripts.each_value {|s| s.die} }
    end

    # Load the given script by file name. The relative path should be included.
    # Scripts are expected to be in the scripts dir.
    def load_file(filename)
      name = filename.match("scripts/(.+).rb")[1]

      $log.debug("scripts.load") { "Script file name: #{filename}" }

      script = "class Script_#{name} < Script \n #{IO.read(filename)} \n end \n Script_#{name}.new"
      
      if @scripts.has_key? name
        throw "Attempted to load script that is already loaded."
      end

      @scripts[name] = eval(script, nil, filename, 0)
    end

    # Unload and then load a script. The name given is the script's short name
    # (script/short_name.rb).
    def reload(name)
      unless @scripts.has_key? name
        throw "Cannot reload: No such script #{name}"
      end

      filename = "scripts/#{name}.rb"

      unless File.exists? filename
        throw "Script file for #{name} does not exist (#{filename})."
      end

      @scripts[name].die if @scripts[name].respond_to? "die"

      @scripts.unregister_script
      @scripts.unregister_commands
      @scripts.unregister_events

      @scripts.delete(name)

      load_file(filename)
    end

    # Unload a script. The name given is the script's short name
    # (scripts/short_name.rb).
    def unload(name)
      unless @scripts.has_key? name
        throw "Cannot unload: No such script #{name}"
      end

      @scripts[name].die if @scripts[name].respond_to? "die"

      @scripts.delete(name)
    end
  end

  class Script

    # Cheat mode for passing functions to $bot.
    # There's probably a better way to do this.
    def method_missing(name, *args, &block)
      if $bot.respond_to? name
        $bot.send(name, *args, &block)
      else
        $log.error("Script.method_missing") { "Attempted to call nonexistent method #{name}" }
        throw NoMethodError.new("#{my_name} attempted to call a nonexistent method #{name}", name, args)
      end
    end

    # Pass along some register commands with self or our class name attached
    # as needed. This just makes code in the scripts a little shorter.

    def register_event(*args)
      $bot.events.create(self, *args)
    end

    def register_command(*args)
      $bot.register_command(self, *args)
    end

    def register_script(*args)
      $bot.register_script(my_short_name, *args)
    end


    # Shortcuts for unregister stuff. Makes teardown easier in die methods.

    def unregister_commands
      $bot.unregister_commands(self)
    end

    def unregister_events
      $bot.unregister_events(self)
    end

    def unregister_script
      $bot.unregister_script(my_short_name)
    end


    # Dunno if these should be functions or variables. Feel free to change.

    def my_name 
      self.class.name.split("::").last
    end

    def my_short_name 
      self.class.name.split("::").last.split("_").last
    end


    # Get config data for this script, if it exists. The section name
    # in the config is the script's short name. Configuration in this
    # version of Terminus-Bot is read-only, unlike the YAML-based config
    # in the previous version. If you want to store data, you want to use
    # the database. See functions below for that!
    def get_config(key, default = nil)
      if $bot.config.has_key? my_short_name
        if $bot.config[my_short_name].has_key? key
          return $bot.config[my_short_name][key]
        end
      end

      return default
    end

    # Check if the database has a Hash table for this plugin. If not,
    # create an empty one.
    def init_data
      unless $bot.database.has_key? my_name
        $bot.database[my_name] = Hash.new
      end
    end

    # Get the value stored for the given key in the database for this
    # script. The optional default value is what is returned if not value
    # exists for the given key.
    def get_data(key, default = nil)
      init_data

      if $bot.database[my_name].has_key? key
        return $bot.database[my_name][key]
      else
        return default
      end
    end

    # Get all of the data for this script.
    def get_all_data
      init_data

      return $bot.database[my_name]
    end

    # Store the given value in the database if one isn't already set.
    def default_data(key, value)
      init_data

      unless $bot.database[my_name].has_key? key
        $bot.database[my_name][key] = value
      end
    end

    # Store a value in the database under the given key.
    def store_data(key, value)
      init_data

      $bot.database[my_name][key] = value
    end

    # Delete data under the given key, if it exists.
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
