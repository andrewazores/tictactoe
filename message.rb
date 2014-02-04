class Message
  attr_accessor :message, :method

  @errors =
  { 0 => "Invalid method",
    1 => "Invalid message",
    2 => "Make sure you enter a number",
    3 => "Square already taken",
    4 => "You appear to be experiencing technical difficulties",
    5 => "The server lost connection with your opponent"
  }

  def initialize
    @method = ""
    @message = ""
  end

  def initialize(method, message)
    @method = method
    @message = message
  end

  def self.validate_message message
    return false unless (["connect", "prompt", "move", "game", "error"].include? message.method)

    case message.method
      when "connect" then ["0", "1"].include? message.message
      when "prompt" then message.message.length == 9
      when "move" then (message.message.to_i >= 0 and message.message.to_i <= 8)
      when "game" then ["win", "lose"].include? message.message
      when "error" then @errors.include? message.message.to_i
      else false
    end
  end

  def self.error_message num
    return @errors[num]
  end

  def self.message_from_string string
    args = string.split
    return Message.new(args[0], args[1])
  end

  def to_string
    @method.to_s + " " + @message.to_s
  end

end

