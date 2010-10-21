
#
#    Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#    Copyright (C) 2010  Terminus-Bot Development Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

class ModuleConfiguration

  # Create a new module configuration data structure.
  # This structure is meant to hold configuration for modules.
  # During initialization, we create a new Hash map in
  # $bot.config["ModuleConfig"] unless one already exists.
  def initialize
    $bot.config["ModuleConfig"] = Hash.new unless $bot.config.key? "ModuleConfig"
  end

  # Create a hash map for the specified module unless one exists.
  # @param [String] modName The name of the module for which the hash table will be created.
  def addModule(modName)
    $bot.config["ModuleConfig"][modName] = Hash.new unless exists? modName
  end

  # Return the value for the named key for the specified module.
  # If the key doesn't exist, return nil.
  # @param [String] modName The name of the module for which we are doing this lookup
  # @param [Object] key The key for the value we want to retrieve.
  # @return [Object] The stored configuration variable.
  # @example Look up a value for automatic mode assignment such as for AutoModes module
  #   modConfig.get("automodes", "#terminus-bot") #=> "+v"
  def get(modName, key)
    $bot.config["ModuleConfig"][modName][key] rescue nil
  end

  # Return all configuration keys for the specified module.
  # If the module doesn't exist, return nil.
  # @param [String] modName The name of the module for which we are doing this lookup
  # @return [Array] An array containing the configuration keys.
  # @example Get a list of channels configured for automatic mode assignment such as for AutoModes module
  #   modConfig.getKeys("automodes") #=> {"#terminus-bot", "#help"}
  def getKeys(modName)
    $bot.config["ModuleConfig"][modName].keys
  end

  # Return all configuration values for the specified module.
  # If the module doesn't exist, return nil.
  # @param [String] modName The name of the module for which we are doing this lookup
  # @return [Array] An array containing the configuration values.
  # @example Get a list of modes configured used for automatic mode assignment such as for AutoModes module
  #   modConfig.getValues("automodes") #=> {"+v", "+o", "+v"}
  def getValues(modName)
    $bot.config["ModuleConfig"][modName].values
  end

  # Return a Hash table containing the configuration for the specified module.
  # If the module doesn't exist, return nil.
  # @param [String] modName The name of the module for which we are doing this lookup
  # @return [Hash] An array containing the configuration values.
  # @example Get a Hash table of channels and their associated automatically-assigned modes such as for AutoModes module
  #   modConfig.getAll("automodes") #=> {"#general" => "+v", "#help" => "+v"}
  def getAll(modName)
    $bot.config["ModuleConfig"][modName]
  end

  # Store a value for the named key for the specified module.
  # @param [String] modName The name of the module.
  # @param [Object] key The key for the value we want to save.
  # @param [Object] value The value to store under key.
  # @example Store a user's last spoken line
  #   modConfig.put("seen", message.speaker, message.message)
  def put(modName, key, value)
    addModule(modName)
    $bot.config["ModuleConfig"][modName][key] = value
  end

  # Delete the value for the named key for the specified module.
  # @param [String] modName The name of the module.
  # @param [Object] key The key for the value we want to delete.
  # @example Delete an Infobot module's entry.
  #   modConfig.delete("infobot", "foo") #=> "bar"
  # @return [Object] The deleted value.
  def delete(modName, key)
    $bot.config["ModuleConfig"][modName].delete key rescue nil
  end

  # Check for the existence of a module in the ModuleConfig map.
  # @param [String] modName The name of the module for which we are checking.
  # @return [Boolean] Returns true if the named module has an entry.
  def exists?(modName)
    $bot.config["ModuleConfig"].key? modName
  end

end
