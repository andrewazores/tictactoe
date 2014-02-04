#!/usr/bin/env ruby

require "socket"
require "./message.rb"

Signal.trap "TERM" do
  p "Exiting"
  @socket.close
end

def handle_message msg
  method = msg.method.to_s
  message = msg.message.to_s
  if method == "connect"
    @player_number = message.to_i
    p "You are player number #{@player_number}"
  elsif method == "prompt"
    draw_board message
    while true do
      print "It's your turn! Make a move: "
      move = $stdin.gets.chomp
      if move == "quit" or move == "exit"
        @socket.close
        exit 0
      end
      if move.to_i >= 0 and move.to_i < 9
        break
      end
    end
    send_message Message.new("move", move)
  elsif method == "error"
    p Message.error_message message
  elsif method == "game"
    if message == "win"
      p "You won! Yay!"
      exit 0
    elsif message == "lose"
      p "You are a failure."
      exit 0
    end
  end
end

def draw_board msg
  p " " + msg[0] + " | " + msg[1] + " | " + msg[2]
  p "-----------"
  p " " + msg[3] + " | " + msg[4] + " | " + msg[5]
  p "-----------"
  p " " + msg[6] + " | " + msg[7] + " | " + msg[8]
end

def send_message msg
  @socket.puts(msg.to_string)
end

if ARGV.length < 2
  p "Please specify a host and port."
  exit 1
end

@server = ARGV[0]
@port = ARGV[1]
@player_number = -1

p "Connecting to #{@server}:#{@port}"
@socket = TCPSocket.new @server, @port

p "Connected to server", @socket.getpeername

while true do
  raw_msg = String.new
  begin
    while true do
      raw = @socket.recvfrom(16)[0].chomp
      if not raw.eql? " " and not raw.eql? ""
        raw_msg = raw
        break
      end
    end
  rescue Exception => e
    p e.message
    p e.backtrace.inspect
    exit 1
  end

  if raw_msg.length <= 0
    p "Server connection lost"
    break
  end

  msg = Message.message_from_string raw_msg.to_s
  if not Message.validate_message msg
    p "Invalid message received"
    p msg.to_string
  end
  handle_message msg
end
@socket.close
