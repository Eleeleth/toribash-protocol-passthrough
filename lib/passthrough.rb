##############################################
#                                            #
#                       @@@                  #
#                 @@@@@@@@@@@@@@@@           #
#             @@@       @@@@@@@@@@@@         #
#           @             @@@@@@@@@@@@       #
#         @@              @@@@@@@@@@@@@      #
#        @                @@@@@@@@@@@@@@     #
#       @                        @@@@@@ @@   #
#      @                                 @   #
#    @@@                                  @  #
#   @@@@@@                                @@ #
#  @@@@@@@@@                              @@ #
#  @  @@@@@                               @@ #
# @@@@@@@@      @@@                       @  #
# @@@ @@@    @@@@@@@@                     @  #
# @@@@@@       @@@@@@@@                  @@  #
#  @ @@@        @@@@@@@@          @@@@@@@@   #
#   @@@@                    @@@@@@@@  @@@    #
#   @@@@                    @   @@@@@@@ @    #
#   @@@@                    @          @     #
#   @@@@@                   @         @@     #
#   @@@@@@          @        @        @@     #
#   @@@@@@@           @@   @@@       @       #
#   @@@@@@@@@    @@@@@@@            @@       #
#    @@@@@@@@@@@@@@@@@@   @@@     @@         #
#     @@@@@@@@@ @@ @@     @@@@@@@@@          #
#     @@@@@@@@@@             @@@@@           #
#      @@@@@@@@@@@@@@@@@@@ @@@@@             #
#       @@@@@@@@    @@@@@@@@@@@              #
#        @@@@@@@@@@@@@@@@@@@@@               #
#         @@@@@@@@@@@@@@@@@@@                #
#           @@@@@@@@@@@@@@@                  #
#               @@@@@                        #
#                                            #
##############################################

require 'socket'
require 'rbconfig'

# Configuration
lobby_host = 'game1.toribash.com'
lobby_port = '22000'

##
## Ideally, this software will listen for a connection to the toribash lobby, 
## and act as a relay for commands to be passed through
##

def find_hostsfile
  # Determine path to hosts file.
  hostsfile = '/etc/hosts'
  is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
  if is_windows
    hostsfile = (ENV['SystemRoot'].gsub('\\','/') + '/System32/drivers' + hostsfile)
  end
  
  # Check if file exists.
  if not File.exist? hostsfile
    errmsg = 'Error: Could not locate file: #{hostsfile}'
    if is_windows
      errmsg << '\nIf you are on a 64-bit version of Windows and your Ruby '
      errmsg << 'is 32-bit, you will need to modify your hosts file by hand.'
    end
    raise errmsg
  end
  
  # Return hosts file path
  hostsfile
end

def read_hostsfile(hostsfile)
  # Read and parse the contents of our hosts file, returning an array.
  # Each entry in the array will either be a hash or a string
  puts 'Reading hosts file..'
  lines = Array.new
  re_hosts = /^\s*([^\s#]+)\s+([^\s#]+)(.*)$/ # Regex for parsing hosts entries.
  File.open(hostsfile, 'r') do |hfile|
    while line = hfile.gets
      match = re_hosts.match line
      lines.push(
        if match then {
          'ip' => match[1],
          'name' => match[2].downcase,
          'end' => match[3]
        } else line end
      )
    end
  end
  lines
end

def build_hostsfile(hostsfile, entries)
  # Given an array based upon the result of read_hostsfile, write.
  puts 'Rewriting hosts file..'
  File.open(hostsfile, 'w') do |hfile|
    last_blank = false
    for entry in entries
      line = ''
      if entry.is_a?(Hash)
        line << entry['ip'] << ' ' << entry['name'] << entry['end']
      else
        line << entry
      end
      hfile.puts line
      last_blank = line.size > 0
    end
    hfile.puts '' if not last_blank # Blank line for good measure
  end
end

def find_domain_index(entries, domain)
  # Search through an entries array for a specific domain
  for i in 0 ... entries.size
    entry = entries[i]
    next if not entry.is_a? Hash
    return i if entry['name'] == domain
  end
  false
end

def resolve_domain(domain)
  # Just to avoid repeating this.
  puts "Resolving #{domain} to IP address.."
  addr = IPSocket::getaddress domain
  puts " # => #{addr}"
  addr
end

def clean_redirect(hostsfile, entries, domain)
  # Check for existing redirect. Rewrite hosts file is found.
  redirect = find_domain_index entries, domain
  if redirect
    puts 'Cleaning up existing redirect..'
    entries.delete_at redirect
    build_hostsfile hostsfile, entries
  end
  entries
end

def redirect_domain(hostsfile, entries, domain)
  entries.push({
    'ip' => '127.0.0.1',
    'name' => domain,
    'end' => ' # Added by passthrough'
  })
  build_hostsfile hostsfile, entries
end

def main(domain, port)
  # First find our hosts file and read in the entries.
  hostsfile = find_hostsfile
  entries = clean_redirect hostsfile, read_hostsfile(hostsfile), domain

  # Resolve the domain to an IP address.
  host = resolve_domain domain
  
  # Redirect the domain to our local IP by modifying the user's hosts file
  redirect_domain hostsfile, entries, domain
  
  # Create our sockets
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
  
  # Finally, clean up the last entry. (the one we added)
  puts 'Removing our redirect..'
  entries.pop
  build_hostsfile hostsfile, entries
end

main(lobby_host.downcase, lobby_port)