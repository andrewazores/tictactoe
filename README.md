tictactoe
=========
Tic Tac Toe over a TCP connection.

Two clients and a server, both written in Ruby. Execute the server with
'./server $PORT', where $PORT is a free port on the server system. Then,
connect with './client $SERVER $PORT' where $SERVER is some kind of
resolvable server location and $PORT is the same port that the server
is bound to. The server and both clients may all run on one machine,
or all on separate machines, or any combination, so long as the required
network connections can be established.
