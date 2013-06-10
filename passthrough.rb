require 'socket'

host = '176.9.64.22' # todo: Change this so I'm relying on DNS
port = '22000'

##
## Ideally, this software will listen for a connection to the toribash lobby, 
## and act as a relay for commands to be passed through
##

server = TCPServer.new port
client = TCPSocket.new host, port

puts 'Listening for TB connection...'

passthru = server.accept # got a connection

puts 'Got a connection.'

while line = client.gets
  clientline = passthru.gets
  puts 'Server:: ' + line 
  puts 'Client:: ' + clientline
  client.puts clientline
  passthru.puts line
end