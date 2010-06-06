

class ModuleHelpObject

  attr_reader :name, :commands, :description

  # Create a new object to represent a module. This object will hold
  # objects which represent the actual commands.
  # @param [String] name The name of the module.
  # @param [String] description A brief description of the module.
  def initialize(name, description)
    @name = name
    @description = description
    @commands = Hash.new
  end

  # Retrieve a command object by name,
  # @param [String] name The name of the command. This is what the user types to execute the command.
  # @return [ModuleHelpCommand] An object representing the command, or nil if it does not exist.
  def getCommand(name)
    @commands[name] rescue nil
  end

  # Add a command to this module's list of commands.
  # @param [ModuleHelpCommand] commandObj An object representing the command.
  def addCommand(commandObj)
    @commands[commandObj.name] = commandObj
  end

end
