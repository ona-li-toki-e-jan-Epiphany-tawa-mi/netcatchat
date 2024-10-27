#!/usr/bin/env bash

# MIT License
#
# Copyright (c) 2023-2024 ona-li-toki-e-jan-Epiphany-tawa-mi
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# TODO make work with POSIX shell.
# TODO add proper error handling.
# TODO? add proper TUI.
# TODO make help info not man-page like,
# TODO add automatic tests for if the installed implementation of nc supports netcatchat.

# Error on unset variables.
set -u

info() {
    echo "info:    $1";
}
warn() {
    echo "warning: $1" 2>&1;
}
error() {
    echo "error:   $1" 2>&1;
}
fatal() {
    echo "fatal:   $1" 2>&1;
    exit 1
}

# Matches an extended regular expression (ERE) against a string.
# $1 - the ERE.
# $2 - the string to match against.
# $? - 0 if the string matches, else 1.
match_regex() {
    # Setting POSIXLY_CORRECT disables implementation-specfic extensions and
    # behaviors.
    POSIXLY_CORRECT='' grep -qE "$1" <<< "$2"
    return $?
}



################################################################################
# Argument parsing START                                                       #
################################################################################

usage() {
    echo "Usages:
  $0 -h
  $0 -v
  $0 [-s] [-p server_port] [-i server_ip] [-x proxy_address[:port] [-X proxy_protocol]]

A simple chat server and client that interfaces with netcat. By default,
netcatchat will run in client mode. To run in server mode, specify -s as
an argument.

Client mode:
  In client mode, netcatchat will attempt to connect to a netcatchat server. If
  successful, you will join and your name will be set to the port you're on.

Server mode:
  In server mode, netcatchat will listen for and accept incoming netcatchat
  clients and route messages between them.

Forewarnings:
  netcatchat is extremely basic; it does not come with chat filtering,
  protections against spamming, banning users, or any other fancy business.

  netcatchat does not provide encryption in of itself. It can, however, be used
  with a proxy that provides encryption, such as stunnel (http), Tor (socks5),
  and I2P (http).

  netcatchat will not run in server mode if the system's netcat implementation
  cannot accept a wait time of 0, which depends on which implementation is
  installed on your system, to check if you can run netcatchat, run
  'nc -l -w 0'. if this produces an error, then you cannot run a server. The
  client mode should still work.

Options:
  -s
    Run in server mode.

  -p server_port
    (server mode) netcatchat will listen on server_port for incoming clients and
    routes them to a client port if one is avalible.
    (client mode) netcatchat will try to connect to the server on server_port to
    obtain a client port to connect on.

  -c client_ports
    (server mode) client_ports are a space-seperated list of the avalible ports
    for clients to connect on. Each client needs their own port.

  -i server_address
    (client mode) Server address.

  -X proxy_protocol
    (client mode) The protocol to use for the proxy. Must one of: '' (no proxy),
    'socks4', 'socks5', or 'http'.

  -x proxy_address[:port]
    (client mode) Proxy address.
    TODO add information on default port settings.

  -h
    Displays usage and exits.

  -v
    Displays version and exits.

TODO: exit codes
"
}

short_usage() {
    echo "Try '$0 -h' for more information"
}

version() {
    echo "netcatchat V1.0.0"
}

## Global options.
# Whether to run as client or server.
# Must be one of: 'client' 'server'.
mode='client'
# The port that users connect to in order to get a port to chat on.
server_port=

## Server options.
# A space-seprated list of the ports that each user connects to to send and
# recieve messages.
client_ports=

## Client options.
# Address of the server to connect to.
server_address=
# The protocol of the proxy to use.
# Leave empty for no proxy.
# Must be one of: '' 'socks4' 'socks5' 'http'
proxy_protocol=
# The address of the proxy to use.
# Leave empty for no proxy.
proxy_address=

# Parsing.
[ 0 -eq $# ] && usage && exit
while getopts 'sp:c:i:X:x:hv' flag; do
    case "$flag" in
        # Global options.
        s) mode=server                                   ;;
        p) server_port=$OPTARG                           ;;
        # Server options.
        c) IFS=" " read -r -a client_ports <<< "$OPTARG" ;; # TODO check if -a is POSIX.
        # Client options.
        i) server_address=$OPTARG                        ;;
        X) proxy_protocol=$OPTARG                        ;;
        x) proxy_address=$OPTARG                         ;;
        # Other.
        h) usage;       exit                             ;;
        v) version;     exit                             ;;
        *) short_usage; exit 1                           ;;
    esac
done

## Validation.
# Global options.
if ! match_regex '^[[:digit:]]{1,5}$' "$server_port"; then
    short_usage
    fatal "invalid server_port '$server_port' supplied with '-p'; expected port number"
fi
# Server options.
#TODO validate client ports.
# Client options.
#TODO? validate server_address.
if [ -n "$proxy_protocol" ] && [ 'socks4' != "$proxy_protocol" ] &&
       [ 'socks5' != "$proxy_protocol" ] && [ 'http' != "$proxy_protocol" ]; then
    short_usage
    fatal "invalid proxy_portocol '$proxy_protocol' supplied with '-X'; expected one of: '', 'socks4', 'socks5', 'http'"
fi
#TODO? validate proxy_address.

################################################################################
# Argument parsing END                                                         #
################################################################################



################################################################################
# Client START                                                                 #
################################################################################

if [ 'client' == "$mode" ]; then
    fatal "TODO: implement client"
fi

################################################################################
# Client END                                                                   #
################################################################################



################################################################################
# Server START                                                                 #
################################################################################

if [ 'server' == "$mode" ]; then
    fatal "TODO: implement server"
fi

################################################################################
# Server           END                                                         #
################################################################################



# ##
# # Trims whitespace from the given strings.
# # https://stackoverflow.com/a/3352015
# #
# # Parameters:
# #   $* - the strings to trim.
# # Returns:
# #   The trimmed strings concatenated together.
# #
# trim_whitespace() {
#     local result="$*"
#     # remove leading whitespace characters
#     result="${result#"${result%%[![:space:]]*}"}"
#     # remove trailing whitespace characters
#     result="${result%"${result##*[![:space:]]}"}"
#     echo "$result"
# }

# ##
# # Trims whitespace from the stdin.
# # Only returns text if the resulting string is non-empty.
# #
# # Returns:
# #   The trimmed input.
# #
# trim_whitespace_stdin() {
#     local line
#     while read -r line; do
#         line=$(trim_whitespace "$line")

#         if [ "${#line}" -gt 0 ]; then
#             echo "$line"
#         fi
#     done
# }

# run_server() {
#     temporary_directory=$(mktemp -d)
#     # Array between client ports and their FIFOs for sending messages.
#     client_input_fifos=()
#     # Array between client ports and their FIFOs for recieving messages.
#     client_output_fifos=()
#     # A FIFO for the port distributor subprocess to recieve commands from.
#     distributor_command_input_fifo="$temporary_directory/commandin"
#     mkfifo "$distributor_command_input_fifo"



#     trap '
#         log_info "Shutting down..."

#         rm -rf "$temporary_directory"

#         pkill -P $$
#         exit
#     ' EXIT



#     ##
#     # Handles sending and recieving messages from an individual client port.
#     # Will send the !free command to the port distributor when the client closes
#     #   the connection to free up the port.
#     #
#     # Parameters:
#     #   $1 - the client port to handle.
#     #   $2 - the FIFO to send messages to the client with.
#     #   $3 - the FIFO to recieve messages from the client with.
#     #
#     handle_client_connection() {
#         while true; do
#             log_info "Started listening on port $1"
#             echo "Welcome!, You are now chatting as: $1" > "$2" &
#             nc -l -p "$1" 0<> "$2" 1<> "$3"

#             log_info "Connection opened and closed on port $1"
#             echo "!free $1" > "$distributor_command_input_fifo" &

#             for other_client_port in "${client_ports[@]}"; do
#                 if [ "$other_client_port" -ne "$1" ]; then
#                     input_fifo="${client_input_fifos[$other_client_port]}"
#                     echo "$1 has disconnected" 1<> "$input_fifo"
#                 fi
#             done
#         done
#     }

#     # Launch subprocess for each client port to handle the connection.
#     for client_port in "${client_ports[@]}"; do
#         input_fifo="$temporary_directory/messagein-$client_port"
#         client_input_fifos["$client_port"]="$input_fifo"
#         mkfifo "$input_fifo"
#         output_fifo="$temporary_directory/messageout-$client_port"
#         client_output_fifos["$client_port"]="$output_fifo"
#         mkfifo "$output_fifo"
#     done
#     for client_port in "${client_ports[@]}"; do
#         input_fifo="${client_input_fifos["$client_port"]}"
#         output_fifo="${client_output_fifos["$client_port"]}"
#         handle_client_connection "$client_port" "$input_fifo" "$output_fifo" &
#     done



#     ##
#     # Handles telling clients which ports are avalible.
#     #
#     distribute_ports() {
#         avalible_ports=("${client_ports[@]}")
#         active_ports=()
#         # Used to store ports that have been distributed, but not connected to,
#         #   so that they can be freed automatically if no one connects.
#         active_port_timeout_map=()

#         ##
#         # Frees the given port for reuse.
#         #
#         # Parameters:
#         #   $1 - the port to free.
#         #
#         free_port() {
#             unset -v "active_ports[$1]"
#             timeout="${active_port_timeout_map[$1]}"
#             if [ "${#timeout}" -gt 0 ]; then
#                 unset -v "active_port_timeout_map[$1]"
#             fi

#             avalible_ports+=("$1")
#         }

#         while true; do
#             # Temporarily stores the ports freed with !free.
#             freed_ports=()
#             # Temporarily stores the ports marked with !notimeout that do not
#             #   have a timeout.
#             timeoutless_notimeout_ports=()
#             # Handles commands from other processes ran by this script.
#             echo "" > "$distributor_command_input_fifo" & # Prevents blocking.
#             while read -r line; do
#                 IFS=" " read -r -a command_arguments <<< "$line"

#                 if [ "${#command_arguments[@]}" -ge 2 ]; then
#                     port=${command_arguments[1]}

#                     case "${command_arguments[0]}" in
#                         # Frees ports that are no longer in use.
#                         !free)
#                             if [ "$port" = "${active_ports[$port]}" ]; then
#                                 free_port "$port"
#                                 log_info "Port $port was freed"

#                                 freed_ports["$port"]="$port"
#                             else
#                                 log_error "Attempted to free inactive port $port!"
#                             fi
#                         ;;
#                         # Prevents a used port from timing out.
#                         !notimeout)
#                             timeout="${active_port_timeout_map[$port]}"

#                             if [ "${#timeout}" -gt 0 ]; then
#                                 unset -v "active_port_timeout_map[$port]"
#                             else
#                                 timeoutless_notimeout_ports["$port"]=$port
#                             fi
#                         ;;
#                     esac
#                 fi
#             done < "$distributor_command_input_fifo"

#             # If we got a !notimeout on an 'avalible' port, that means that
#             #   someone has connected to it without first connecting to the
#             #   server port. Since the port is in use, we need to mark it as
#             #   active.
#             for notimeout_port in "${timeoutless_notimeout_ports[@]}"; do
#                 # Freed ports are guaranteed inactive.
#                 if [ "${#freed_ports[$notimeout_port]}" -gt 0 ]; then
#                     continue
#                 fi

#                 was_port_locked='false'

#                 for (( i=0; i < ${#avalible_ports[@]}; ++i )); do
#                     avalible_port=${avalible_ports[$i]}
#                     if [ "$notimeout_port" = "$avalible_port" ]; then
#                         was_port_locked='true'
#                         unset -v 'avalible_ports[i]';
#                         active_ports["$avalible_port"]="$avalible_port"

#                         log_info "Found unexpected connection on port $avalible_port; marking as active"
#                         break
#                     fi
#                 done

#                 if [ "$was_port_locked" = 'true' ]; then
#                     avalible_ports=("${avalible_ports[@]}")
#                 fi
#             done

#             # Frees ports that no one has connected to.
#             for active_port in "${active_ports[@]}"; do
#                 timeout=${active_port_timeout_map[$active_port]}

#                 if [ "${#timeout}" -gt 0 ]; then
#                     current_time=$(date +%s)
#                     if (( current_time - timeout > 3 )); then
#                         free_port "$active_port"
#                         unset -v "active_port_timeout_map[$active_port]"
#                         log_info "Timed out port $active_port"
#                     fi
#                 fi
#             done

#             # Distributes ports.
#             if [ "${#avalible_ports[@]}" -gt 0 ]; then
#                 port=${avalible_ports[0]}
#                 echo "$port" | nc -l -w 0 -p "$server_port" > /dev/null

#                 log_info "Gave out port $port"
#                 unset -v 'avalible_ports[0]'; avalible_ports=("${avalible_ports[@]}")
#                 active_ports["$port"]="$port"
#                 active_port_timeout_map["$port"]=$(date +%s)

#             else
#                 echo -1 | nc -l -w 0 -p "$server_port"
#                 log_info 'Gave out port -1 to client to due all ports being used up'
#             fi
#         done
#     }
#     distribute_ports &



#     # Handles sending messages between connected clients.
#     while true; do
#         for client_port in "${client_ports[@]}"; do
#             output_fifo=${client_output_fifos[$client_port]}
#             has_message='false'

#             while read -r -t 0; do
#                 has_message='true'
#                 read -r line
#                 line=$(trim_whitespace "$line")

#                 if [ "${#line}" -gt 0 ]; then
#                     message="[$client_port]: $line"
#                     log_info "$message"

#                     # Client message is sent back to them as confirmation.
#                     for other_client_port in "${client_ports[@]}"; do
#                         input_fifo="${client_input_fifos[$other_client_port]}"
#                         echo "$message" 1<> "$input_fifo"
#                     done
#                 fi
#             done 0<> "$output_fifo"

#             if [ "$has_message" = 'true' ]; then
#                 echo "!notimeout $client_port" > "$distributor_command_input_fifo" &
#             fi
#         done

#         sleep 0.1
#     done
# }



# run_client() {
#     trap 'log_info "Shutting down..."' EXIT

#     proxy_arguments=''
#     if [ ! "$proxy_address" = '' ]; then
#         proxy_arguments="-X $proxy_protocol -x $proxy_address"
#     fi

#     log_info "Connecting to $server_ip:$server_port..."
#     # shellcheck disable=SC2086 # We want word splitting.
#     port=$(nc -v -w 1 $proxy_arguments "$server_ip" "$server_port")

#     if [ "$port" = '' ]; then
#         log_error "Could not connect to $server_ip:$server_port!"
#         exit 2
#     elif [ "$port" -eq -1 ]; then
#         log_error "No avalible client ports on $server_ip to connect to!"
#         exit 3
#     elif ! [[ "$port" =~ $port_regex ]]; then
#         log_error "Recieved invald port $port from $server_ip:$server_port!"
#         exit 3
#     else
#         log_info "Recieved port $port, reconnecting to $server_ip:$port..."
#         # shellcheck disable=SC2086 # We want word splitting.
#         { echo "CONNECTED" ; cat ; } | trim_whitespace_stdin | nc -v $proxy_arguments "$server_ip" "$port"
#     fi
# }
