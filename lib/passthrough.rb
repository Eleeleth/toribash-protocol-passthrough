require 'socket'
require 'pcaplet'
include Pcap

# Configuration
lobby_host = 'game1.toribash.com'

##
## Ideally, this software will listen for a connection to the toribash lobby, 
## and act as a relay for commands to be passed through
##

def resolve_domain(domain)
  # Just to avoid repeating this.
  puts "Resolving #{domain} to IP address.."
  addr = IPSocket::getaddress domain
  puts " # => #{addr}"
  addr
end


def main(lobby_host)
  puts 'main entered'
  ## Get capture.
  capture = Pcaplet.new '-i en1 -s 66535' 
  host = resolve_domain lobby_host
  localhost = resolve_domain 'localhost'
  capture.each_packet do |p|
      if p.tcp? 
        if p.src.to_s == host or p.dst.to_s == host
          puts "#{p.src} - #{p.tcp_data}"
        end
      end
  end
end

main(lobby_host)