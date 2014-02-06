#!/usr/bin/env ruby

require "socket"
require "./message.rb"

class Client

  def initialize server, port
    Signal.trap "TERM" do
      shutdown
    end
    @server = server
    @port = port.to_i
    unless @port.between? 0, 2**16-1
      raise Exception.new "Port #{@port} out of range"
    end
  end

  def start
    puts "Connecting to #{@server}:#{@port}"
    begin
      @socket = TCPSocket.new @server, @port
    rescue Exception => e
      puts "Could not connect to #{@server}:#{@port}. Verify a server is running at this location"
      exit 1
    end

    puts "Connected to server #{@socket.remote_address.getnameinfo.first}"

    while true do
      raw_msg = String.new
      begin
        while true do
          raw = @socket.gets.chomp
          if not raw.eql? " " and not raw.eql? ""
            raw_msg = raw
            break
          end
        end
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        shutdown 1
      end

      if raw_msg.length <= 0
        puts "Server connection lost"
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
      puts "Invalid message received"
      puts msg.to_s
      return
    end
    method, message = msg.parts

    if method == "connect"
      @player_number = message.to_i
      puts "You are player number #{@player_number}"

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
      puts Message.error_message message.to_i

    elsif method == "game"
      if message == "win"
        puts "You won! Yay!"
        shutdown 0
      elsif message == "lose"
        puts "You are a failure."
        shutdown 0
      end
    end
  end

  def draw_board msg
    puts " " + msg[0] + " | " + msg[1] + " | " + msg[2]
    puts "-----------"
    puts " " + msg[3] + " | " + msg[4] + " | " + msg[5]
    puts "-----------"
    puts " " + msg[6] + " | " + msg[7] + " | " + msg[8]
  end

  def send_message msg
    puts "Sending #{msg.to_s}"
    @socket.puts msg.to_s
  end

end

if ARGV.length < 2
  puts "Please specify a host and port."
  exit 1
end

server = ARGV[0]
port = ARGV[1].to_i

client = Client.new server, port
client.start
