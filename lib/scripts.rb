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

module Bot
  Script_Info = Struct.new :name, :description

  SCRIPTS_PATH = "scripts"

  class ScriptManager

    attr_reader :script_info

    # TODO: Rework this whole file. Stop this stupid string juggling.

    def initialize
      @scripts, @script_info = {}, []

      unless Dir.exists? "scripts"
        raise "Scripts directory does not exist."
      end
    end

    # Load all the scripts in the scripts directory.
    def load_scripts
      $log.info("ScriptManager.initilize") { "Loading scripts." }

      noload = Bot::Conf[:core][:noload]

      Dir.glob("#{SCRIPTS_PATH}/*.rb").each do |file|

        unless noload == nil
          # I realize we are pulling the name out twice. Deal with it.
          next if noload.keys.include? file.match("#{SCRIPTS_PATH}/(.+).rb")[1].to_sym
        end

        $log.debug("ScriptManager.initilize") { "Loading #{file}" }
        load_file file

      end
    end

    # Run the die functions on all scripts.
    def die
      @scripts.each_value {|s| s.die if s.respond_to? "die"}
    end

    # Load the given script by file name. The relative path should be included.
    # Scripts are expected to be in the scripts dir.
    def load_file filename
      unless File.exists? filename
        raise "File #{filename} does not exist."
      end

      name = filename.match("#{SCRIPTS_PATH}/(.+).rb")[1]

      $log.debug("ScriptManager.load_file") { "Script file name: #{filename}" }

      script = [
        "class Script_#{name} < Script",
        "  def initialize",
             IO.read(filename),
        "  end",
        "end",
        "Script_#{name}.new"].join "\n"

      if @scripts.has_key? name
        raise "Attempted to load script that is already loaded."
      end

      begin
        @scripts[name] = eval script, nil, filename, 0

        Events.dispatch_for @scripts[name], :done_loading
      rescue Exception => e
        $log.error("ScriptManager.load_file") { "Problem loading script #{name}. Clearing data and aborting..." }

        if @scripts.has_key? name

          Events.delete_for @scripts[name]
          URL.delete_for @scripts[name] if defined? MODULE_LOADED_URL_HANDLER

          @scripts[name].unregister_script
          @scripts[name].unregister_commands
          @scripts[name].unregister_events

          @scripts.delete name

        end

        raise "Problem loading script #{name}: #{e}: #{e.backtrace}"
      end
    end

    # Unload and then load a script. The name given is the script's short name
    # (script/short_name.rb).
    def reload name
      raise "Cannot reload: No such script #{name}" unless @scripts.has_key? name

      filename = "#{SCRIPTS_PATH}/#{name}.rb"

      raise "Script file for #{name} does not exist (#{filename})." unless File.exists? filename

      @scripts[name].die if @scripts[name].respond_to? "die"

      Events.delete_for @scripts[name]
      URL.delete_for @scripts[name] if defined? MODULE_LOADED_URL_HANDLER

      @scripts[name].unregister_script
      @scripts[name].unregister_commands
      @scripts[name].unregister_events

      @scripts.delete name

      load_file filename
    end

    # Unload a script. The name given is the script's short name
    # (scripts/short_name.rb).
    def unload name
      raise "Cannot unload: No such script #{name}" unless @scripts.has_key? name

      @scripts[name].die if @scripts[name].respond_to? "die"

      Events.delete_for @scripts[name]
      URL.delete_for @scripts[name] if defined? MODULE_LOADED_URL_HANDLER

      @scripts[name].unregister_script
      @scripts[name].unregister_commands
      @scripts[name].unregister_events

      @scripts.delete name
    end

    def register_script *args
      $log.debug("ScriptManager.register_script") { "Registering script: #{args.to_s}" }

      script = Script_Info.new *args

      @script_info << script
      Bot::Flags.add_script script.name

      @script_info.sort_by! {|s| s.name}
    end

    def unregister_script name
      $log.debug("ScriptManager.register_script") { "Unregistering script: #{name}" }
      @script_info.delete_if {|s| s.name == name}
    end
  end

  class Script

    # Pass along some register commands with self or our class name attached
    # as needed. This just makes code in the scripts a little shorter.

    def need_module! name
      unless Bot.const_defined? "MODULE_LOADED_#{name.upcase}"
        raise "#{my_short_name} requires the #{name} module"
      end
    end

    def event *names, &blk
      names.each do |name|
        Bot::Events.create name, self, nil, &blk
      end
    end

    def command cmd, help = "", &blk
      Bot::Commands.create self, cmd, help, &blk
    end


    def register *args
      Bot::Scripts.register_script my_short_name, *args
    end

    def helpers &blk
      @helpers = blk
    end

    def get_helpers
      @helpers
    end


    # Shortcuts for unregister stuff. Makes teardown easier in die methods.

    def unregister_commands
      Bot::Commands.delete_for self
    end

    def unregister_events
      Bot::Events.delete_for self
    end

    def unregister_script
      Bot::Scripts.unregister_script my_short_name
    end


    # Dunno if these should be functions or variables. Feel free to change.


    def my_name 
      @my_name ||= self.class.name.split("::").last
    end

    def my_short_name 
      @my_short_name ||= self.class.name.split("_").last
    end


    # Get config data for this script, if it exists. The section name
    # in the config is the script's short name. Configuration in this
    # version of Terminus-Bot is read-only, unlike the YAML-based config
    # in the previous version. If you want to store data, you want to use
    # the database. See functions below for that!
    def get_config key, default = nil
      name_key = my_short_name.to_sym

      if Bot::Conf.has_key? name_key
        if Bot::Conf[name_key].has_key? key
          return Bot::Conf[name_key][key]
        end
      end

      default
    end

    # Check if the database has a Hash table for this plugin. If not,
    # create an empty one.
    def init_data
      Bot::DB[my_name] ||= {}
    end

    # Get the value stored for the given key in the database for this
    # script. The optional default value is what is returned if no value
    # exists for the given key.
    def get_data key, default = nil
      init_data

      Bot::DB[my_name][key] or default
    end

    # Get all of the data for this script.
    def get_all_data
      init_data

      Bot::DB[my_name]
    end

    # Store the given value in the database if one isn't already set.
    def default_data key, value
      init_data

      Bot::DB[my_name][key] ||= value
    end

    # Store a value in the database under the given key.
    def store_data key, value
      init_data

      Bot::DB[my_name][key] = value
    end

    # Delete data under the given key, if it exists.
    def delete_data key
      init_data

      Bot::DB[my_name].delete key
    end

    def to_str
      my_short_name
    end
  end

  unless defined? Scripts
    Scripts = ScriptManager.new
    Scripts.load_scripts
  end

end
