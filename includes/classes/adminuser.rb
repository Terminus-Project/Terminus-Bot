class AdminUser
  attr_writer :accessLevel, :password
  attr_reader :accessLevel, :password, :fullMask

  def initialize(fullString, password, accessLevel = 0)
    @fullMask = fullString
    @accessLevel = accessLevel
    @password = password
  end

end
