#!/usr/bin/env ruby

require "socket"
require "./message.rb"

class Server

  def initialize port
    Signal.trap "TERM" do
      p "Exiting"
      @socket.close
    end
    @port = port.to_i
    @player_turn = 0
    @client_sockets = []
    @board = [-1] * 9
  end

  def start
    @socket = TCPServer.new @port

    @socket.listen 5
    puts "Server is: #{Socket.gethostname}"
    puts "Waiting for clients"

    (0...2).each do |i|
      @client_sockets[i], client_info = @socket.accept
      msg = Message.new "connect", i.to_s
      puts "Player #{i.to_s} connected"
      send_message msg, i
    end
    puts ""

    while true do
      prompt_msg = Message.new "prompt", board_to_string
      send_message prompt_msg, @player_turn

      begin
        raw_msg = @client_sockets[@player_turn].recvfrom(16).first.chomp
      rescue
        print "Connection to player #{@player_turn.to_s} lost"
        send_message Message.new("error", 5), (@player_turn + 1) % 2
        break
      end

      if raw_msg.length <= 0
        print "Connection to player #{@player_turn.to_s} lost"
        send_message Message.new("error", 5), (@player_turn + 1) % 2
        break
      end

      msg = Message.message_from_string raw_msg
      unless Message.validate_message msg
        puts "Invalid message received from player #{@player_turn.to_s}"
        send_message Message.new("error", 0), @player_turn
      end

      valid, err_code = handle_message msg
      unless valid
        send_message Message.new("error", err_code), @player_turn
        next
      end

      check_win
      @player_turn = (@player_turn + 1) % 2 if Message.validate_message msg and valid
    end
  end

  def shutdown
    @client_sockets.each do |s|
        s.close
    end
    exit 0
  end

  def handle_message msg
    method, message = msg.parts

    puts "\nReceived message from player #{@player_turn.to_s}:"
    puts "\t#{method} #{message}"

    if method == "move"
      if @board[message.to_i] == -1
        @board[message.to_i] = @player_turn
        return true, ""
      else
        return false, 3
      end
    else
      puts "\tIllegal message method"
      return false, 0
    end
  end

  def send_message msg, player
    puts "\nPlayer #{player} being sent message:"
    puts "\t#{msg.to_s}"
    @client_sockets[player].puts msg.to_s
  end

  def board_to_string
    brd = ""
    @board.each_index do |i|
      brd += case @board[i]
        when -1 then i.to_s
        when 0 then 'X'
        when 1 then 'O'
      end
    end
    brd
  end

  def send_win
    send_message Message.new("game", "win"), @player_turn
    send_message Message.new("game", "lose"), (@player_turn + 1) % 2

    exit 0
  end

  def send_tie
    send_message Message.new("game", "lose"), 0
    send_message Message.new("game", "lose"), 1

    exit 0
  end

  def check_seq a, b, c
    @board[a] != -1 and @board[a] == @board[b] and @board[b] == @board[c]
  end

  def check_win
    [0, 1, 2].each do |i|
      send_win if check_seq i, i + 3, i + 6
    end

    [0, 3, 6].each do |i|
      send_win if check_seq i, i + 1, i + 2
    end

    send_win if check_seq 0, 4, 8
    send_win if check_seq 2, 4, 6

    board_filled = true
    @board.each do |i|
      board_filled = false if i == -1
    end

    send_tie if board_filled
  end

end

if ARGV.length < 1
    puts "Please specify a port number."
    exit 1
end

port = ARGV[0].to_i
unless port.between? 0, 2**16-1
  p "Please enter a valid port number. #{port} is out of range"
  exit 1
end

server = Server.new port
server.start
