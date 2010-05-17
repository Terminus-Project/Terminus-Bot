class Channel

  attr_writer :name, :users, :topic, :key, :bans

  def initialize(name)
    @name = name
  end  

end
