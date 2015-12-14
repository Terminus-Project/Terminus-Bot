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
  Script_Info = Struct.new :name, :description

  SCRIPTS_PATH = "scripts"

  class ScriptManager

    attr_reader :script_info

    # TODO: Rework this whole file. Stop this stupid string juggling.
    # TODO: Kill all these module-specific things. We need events or something
    #       to handle script load/unload/reload in modules. The code for that
    #       already exists in the eventing system, we just need to tie it all
    #       together.

    # Initialize a new ScriptManager object.
    #
    # @raise if scripts directory does not exist
    def initialize
      @scripts, @script_info = {}, []

      unless Dir.exist? 'scripts'
        # XXX - raise a better exception here
        raise 'Scripts directory does not exist.'
      end
    end

    # Load all the scripts in the scripts directory.
    def load_scripts
      $log.info('ScriptManager.initilize') { 'Loading scripts.' }

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

    # Run the `die` functions on all scripts that respond to it.
    def die
      # XXX
      @scripts.each_value {|s| s.die if s.respond_to? "die"}
    end

    # Load the given script by file name. The relative path should be included.
    # Scripts are expected to be in the scripts dir.
    # @param filename [String] relative path to script
    # @raise if script is already loaded
    # @raise if an error occurs while evaluating the script
    def load_file filename
      unless File.exist? filename
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
        $log.error('ScriptManager.load_file') { "Problem loading script #{name}. Clearing data and aborting..." }

        if @scripts.has_key? name

          Events.delete_for @scripts[name]
          URL.delete_for @scripts[name] if defined? MODULE_LOADED_URL_HANDLER
          RegexHandlerManager.delete_for @scripts[name] if defined? MODULE_LOADED_REGEX_HANDLER

          @scripts[name].unregister_script
          @scripts[name].unregister_commands
          @scripts[name].unregister_events

          @scripts.delete name

        end

        raise "Problem loading script #{name}: #{e}: #{e.backtrace}"
      end
    end

    # Unload and then load a script. The name given is the script's short name
    # (script/**short_name**.rb).
    # @param name [String] script short name
    # @raise if script does not exist
    def reload name
      raise "Cannot reload: No such script #{name}" unless @scripts.has_key? name

      filename = "#{SCRIPTS_PATH}/#{name}.rb"

      raise "Script file for #{name} does not exist (#{filename})." unless File.exist? filename

      @scripts[name].die if @scripts[name].respond_to? 'die'

      Events.dispatch_for @scripts[name], :unloading

      Events.delete_for @scripts[name]
      URL.delete_for @scripts[name] if defined? MODULE_LOADED_URL_HANDLER
      RegexHandlerManager.delete_for @scripts[name] if defined? MODULE_LOADED_REGEX_HANDLER

      @scripts[name].unregister_script
      @scripts[name].unregister_commands
      @scripts[name].unregister_events

      @scripts.delete name

      load_file filename
    end

    # Unload a script. The name given is the script's short name
    # (scripts/**short_name**.rb).
    # @param name [String] script short name
    # @raise if script does not exist
    def unload name
      raise "Cannot unload: No such script #{name}" unless @scripts.has_key? name

      @scripts[name].die if @scripts[name].respond_to? "die"

      Events.dispatch_for @scripts[name], :unloading

      Events.delete_for @scripts[name]
      URL.delete_for @scripts[name] if defined? MODULE_LOADED_URL_HANDLER
      RegexHandlerManager.delete_for @scripts[name] if defined? MODULE_LOADED_REGEX_HANDLER

      @scripts[name].unregister_script
      @scripts[name].unregister_commands
      @scripts[name].unregister_events

      @scripts.delete name
    end

    # Register a new script with the script info list, flags, and any other
    # data structures that need to know about new scripts.
    #
    # @see Script_Info#initialize
    def register_script *args
      $log.debug("ScriptManager.register_script") { "Registering script: #{args.to_s}" }

      script = Script_Info.new(*args)

      @script_info << script
      Bot::Flags.add_script script.name

      @script_info.sort_by! {|s| s.name}
    end

    # Delete a script from the script info list.
    # @param name [String] script short name
    def unregister_script name
      $log.debug("ScriptManager.register_script") { "Unregistering script: #{name}" }
      @script_info.delete_if {|s| s.name == name}
    end
  end

  class Script

    # Enforce module requirements in scripts. Should be the first code in
    # scripts that require any modules.
    #
    # @example
    #     need_module! 'http_client'
    #
    # @param names [String] names of modules that is required
    # @raise if the required module is not loaded
    def need_module! *names
      names.each do |name|
        unless Bot.const_defined? "MODULE_LOADED_#{name.upcase}"
          raise "#{my_short_name} requires the #{name} module. Either add it to your configuration or disable this script."
        end
      end
    end

    # Create a new event handler. Multiple event names can be specified to
    # handle multiple events with one block.
    #
    # @example Handle one type of event
    #     event :PRIVMSG do
    #       # ...
    #     end
    #
    #     event :NOTICE do
    #       # ...
    #     end
    #
    # @example Handle multiple events with one block
    #     event :PART, :KICK, :QUIT do
    #       # ...
    #     end
    #
    # @param names [Symbol]
    def event *names, &blk
      names.each do |name|
        Bot::Events.create name, self, nil, &blk
      end
    end

    # Create a new command handler.
    #
    # @example Command without help
    #     command 'hello' do
    #       reply 'hello!'
    #     end
    #
    # @example Command with help
    #     command 'hello', 'Say hello to the bot.' do
    #       reply 'hello!'
    #     end
    #
    # @param cmd [String] one-word command trigger
    # @param help [String] helpful command description for bot users
    def command cmd, help = "", &blk
      Bot::Commands.create self, cmd, help, &blk
    end

    # Regiser the script with the bot. This is not mandatory, but is
    # recommended so the script list includes data about your script.
    #
    # @example
    #     register 'an exmaple script'
    #
    # @param args [String] helpful description of the script
    def register *args
      Bot::Scripts.register_script my_short_name, *args
    end

    # Evaluate a block of code at the class level. Ideal for adding helper
    # functions to your script since they cannot be declared at the top
    # level of the script.
    #
    # @example
    #     helpers do
    #       def foo
    #         # ...
    #       end
    #
    #       def bar arg
    #         # ...
    #       end
    #     end
    def helpers &blk
      @helpers = blk
    end

    # Get the helpers block for this script. Used by the command dispatcher.
    # @todo move this somewhere better
    def get_helpers
      @helpers
    end


    # Shortcuts for unregister stuff. Makes teardown easier in die methods.


    # Delete all commands owned by this script. Used by {ScriptManager} when
    # unloading the script.
    def unregister_commands
      Bot::Commands.delete_for self
    end

    # Delete all event handlers owned by this script. Used by {ScriptManager}
    # when unloading the script.
    def unregister_events
      Bot::Events.delete_for self
    end

    # Delete registered info for this script. Used by {ScriptManager} when
    # unloading the script.
    def unregister_script
      Bot::Scripts.unregister_script my_short_name
    end


    # Dunno if these should be functions or variables. Feel free to change.


    # Get the script's long name, such as `Script_help`.
    # @return [String] script name
    def my_name
      @my_name ||= self.class.name.split("::").last
    end

    # Get the script's short name, such as `help`.
    # @return [String] short script name
    def my_short_name
      @my_short_name ||= self.class.name.split("_").last
    end


    # Get config data for this script, if it exists.
    #
    # The section name in the config is the script's short name.
    #
    # @example Configuration file entry for "example" script
    #     example = {
    #       foo = bar
    #       baz = false
    #     }
    #
    # @example Getting configuration values for "example" script
    #     get_config :foo       #=> "bar"
    #     get_config :baz, true #=> false
    #     get_config :qux, 5    #=> 5
    #
    # **Note: Configuration in this version of Terminus-Bot is read-only,
    # unlike the YAML-based config in the previous version. If you want to
    # store data, you want to use the database.**
    #
    # @param key [Symbol] name of setting to get
    # @param default [Object] value to return if setting does not exist
    #
    # @return [String, Boolean, Integer, Object] setting value, or `default` if
    #   the setting does not exist
    def get_config key, default = nil
      name_key = my_short_name.to_sym

      if Bot::Conf.has_key? name_key
        return Bot::Conf[name_key].fetch key, default
      end

      default
    end

    # If the script's database does not yet exist, create it.
    #
    # *Should not be called by scripts.*
    #
    # @todo rename, refactor callers
    # @return [Hash] script database
    def init_data
      Bot::DB[my_name] ||= {}
    end

    # Get the value stored for the given key in the database for this script.
    # The optional default value is what is returned if no value exists for the
    # given key.
    #
    # @example Look up database data
    #     # Existing value, symbol key
    #     get_data :foo         #=> 'bar'
    #     # Nonexistent value, string key
    #     get_data 'bar'        #=> nil
    #     # Nonexistent value, string key
    #     get_data 'baz', 'qux' #=> "qux"
    #
    # @param key [Object] database entry key
    # @param default [Object] value to return if database entry does not exist
    # @return [Object] database entry, or `default` if none exists
    def get_data key, default = nil
      init_data

      Bot::DB[my_name].fetch key, default
    end

    # Get the entire database for this script.
    # @return [Hash] script database
    def get_all_data
      init_data

      Bot::DB[my_name]
    end

    # Store the given value in the database if one isn't already set.
    #
    # @example Setting default values.
    #     default_data :messages_seen, 0
    #
    #     # count PRIVMSG events
    #     event :PRIVMSG do
    #       seen = get_data :messages_seen #=> 0
    #       seen += 1                      #=> 1
    #       store_data :messages_seen, :seen
    #     end
    #
    # @param key [Object] database item keye
    # @param value [Object] value to store if none is set
    def default_data key, value
      init_data

      Bot::DB[my_name][key] ||= value
    end

    # Store a value in the database under the given key.
    #
    # @example Storing values in the database
    #     event :PRIVMSG do
    #       store_data :last_message, @msg
    #     end
    #
    # @param key [Object] database item key
    # @param value [Object] value to store in database
    def store_data key, value
      init_data

      Bot::DB[my_name][key] = value
    end

    # Store data at the root of the script's database. Useful when dealing with
    # data acquired from {Scripts#get_all_data}.
    #
    # @raise when value is not a Hash
    #
    # @param value [Hash] data to store in database
    def store_all_data value
      unless value.is_a? Hash
        raise 'database root for scripts must be a Hash object'
      end

      init_data

      Bot::DB[my_name] = value
    end

    # Delete data under the given key, if it exists.
    # @param key [Object] database key to delete
    def delete_data key
      init_data

      Bot::DB[my_name].delete key
    end

    # @see Script#my_short_name
    # @return [String] script short name
    def to_str
      my_short_name
    end
  end

  unless defined? Scripts
    Scripts = ScriptManager.new
    Scripts.load_scripts
  end

end
# vim: set tabstop=2 expandtab:
