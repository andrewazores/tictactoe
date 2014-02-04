#!/usr/bin/env ruby

require "socket"
require "./message.rb"

class Client

  def initialize server, port
    Signal.trap "TERM" do
      shutdown
    end
    @server = server
    @port = port
  end

  def start
    p "Connecting to #{@server}:#{@port}"
    @socket = TCPSocket.new @server, @port

    p "Connected to server #{@socket.remote_address.getnameinfo.first}"

    while true do
      raw_msg = String.new
      begin
        while true do
          raw = @socket.recvfrom(16).first.chomp
          if not raw.eql? " " and not raw.eql? ""
            raw_msg = raw
            break
          end
        end
      rescue Exception => e
        p e.message
        p e.backtrace.inspect
        shutdown 1
      end

      if raw_msg.length <= 0
        p "Server connection lost"
        break
      end

      msg = Message.message_from_string raw_msg.to_s
      handle_message msg
    end
    shutdown
  end

  def shutdown code=0
    @socket.close
    exit code
  end

  def handle_message msg
    if not Message.validate_message msg
      p "Invalid message received"
      p msg.to_s
      return
    end
    method, message = msg.parts

    if method == "connect"
      @player_number = message.to_i
      p "You are player number #{@player_number}"

    elsif method == "prompt"
      draw_board message
      while true do
        print "It's your turn! Make a move: "
        move = $stdin.gets.chomp
        if move == "quit" or move == "exit"
          shutdown 0
        end
        break if move.to_i >= 0 and move.to_i < 9
      end
      send_message Message.new "move", move

    elsif method == "error"
      p Message.error_message message.to_i

    elsif method == "game"
      if message == "win"
        p "You won! Yay!"
        shutdown 0
      elsif message == "lose"
        p "You are a failure."
        shutdown 0
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
    p "Sending #{msg.to_s}"
    @socket.puts msg.to_s
  end

end

if ARGV.length < 2
  p "Please specify a host and port."
  exit 1
end

server = ARGV[0]
port = ARGV[1]

client = Client.new server, port.to_i
client.start
