

class ModuleHelpCommand

  attr :name, :help, :args

  # Create an object to represent a module command help entry.
  # @param [String] name The name of the command. This is what the user types to execute this command.
  # @param [String] help A brief description of the command.
  # @param [String] args The arguments to the command. Standard form is generally: required_arg [optional_arg]
  def initialize(name, help, args = nil)
    @name = name
    @help = help
    @args = args
  end

  # Return a string representation of the command
  # @return [String] "name args - help"
  def to_s
    "#{BOLD}#{@name}#{NORMAL} #{UNDERLINE}#{@args}#{NORMAL}#{" " unless @args == nil}- #{@help}"
  end

end
