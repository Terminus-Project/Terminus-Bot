

class ModuleHelpCommand

  attr :name, :help, :args

  def initialize(name, help, args = nil)
    @name = name
    @help = help
    @args = args
  end

  def to_s
    "#{BOLD}#{@name}#{NORMAL} #{UNDERLINE}#{@args}#{NORMAL} - #{@help}"
  end

end
