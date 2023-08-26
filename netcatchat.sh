#!/usr/bin/env bash

# TODO Create install script or just some instructions to toss this script /usr/local/bin.
# TODO See if disabled shellcheck warnings are meaningful.

################################################################################
# MIT License
# 
# Copyright (c) 2023 ona-li-toki-e-jan-Epiphany-tawa-mi
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
################################################################################ 

##
# Logs an info-level message to the stdout.
#
# Parameters:
#   $1 - the message to send.
#
log_info() {
    echo "[$(date '+%D %T')] INFO: $1"
}

##
# Logs an error-level message to the stderr.
#
# Parameters:
#   $1 - the message to send.
#
log_error() {
    echo "[$(date '+%D %T')] ERROR: $1" 1>&2
}

# A regex that matches ports (really just matches with all integers.)
port_regex='^[0-9]+$'

##
# Trims whitespace from the given strings.
# https://stackoverflow.com/a/3352015 
#
# Parameters:
#   $* - the strings to trim.
# Returns:
#   The trimmed strings concatenated together.
#
trim_whitespace() {
    local result="$*"
    # remove leading whitespace characters
    result="${result#"${result%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    result="${result%"${result##*[![:space:]]}"}"
    echo "$result"
}

##
# Trims whitespace from the stdin.
# Only returns text if the resulting string is non-empty.
#
# Returns:
#   The trimmed input.
#
trim_whitespace_stdin() {
    local line
    while read -r line; do
        line=$(trim_whitespace "$line")

        if [ "${#line}" -gt 0 ]; then
            echo "$line"
        fi
    done
    
}



print_usage() {
    printf "NAME
\t%s - simple chat server and client using netcat

SYNOPSIS
\t%s -h
\t%s -v
\t%s [-p server_port] [-i server_ip]
\t%s -s [-p server_port] [-c client_ports]

DESCRIPTION
\tA simple chat server and client that interfaces with netcat. By default,
\t%s will run in client mode. To run in server mode, specify -s as an
\targument. 

\tBy default, the client will connect to 127.0.0.1:2000, see the OPTIONS
\tsection for how to change that.

\tBy default, the server will listen on port 2000 to give out ports 2001-2010
\tfor clients to connect to. See the OPTIONS section for how to change that.

\tEach client will have the port that they are connected on as their username.

\tThis chat system is extremely basic. It will not check if multiple clients
\tare connected from the same ip. It will not block or rate-limit spammers.
\tSomeone could easily use a script to steal all the ports and prevent people
\tfrom connecting. There is absolutely no mechanism for moderation. No
\tattempts are made at encryption. Basically, proceed with caution.

\tThere is the possiblity for someone to make their own script to connect to
\tthe server_port and not reconnect on a client port, or connect directly to a
\tclient port. There are checks in place to make sure that ports dished out
\tfrom the server_port are freed if unused and locked (as-in it won't try to
\tgive someone that port to connect on as it is busy) if someone decides to
\tdirectly connect to a client port, so such \"attacks\" should not be too big
\tof an issue.

OPTIONS
\t-s
\t\tBy default, %s will run in client mode and try to connect to a
\t\tserver. Specifying -s will, instead, make it run in server mode.

\t-p server_port
\t\tIn server mode, %s will listen on server_port for incoming chat
\t\tclients and routes them to a client port if one is avalible. On client
\t\tmode, %s will try to connect to the server on server_port to
\t\tfigure out which client port to connect on. Defaults to 2000

\t-c client_ports
\t\tServer mode only. client_ports are the avalible ports for clients to
\t\tconnect on. Each client needs their own port, so the maximum number of
\t\tusers will be limited by how many are supplied. Defaults to 2001-2010
\t\t(inclusive.)

\t-i server_ip
\t\tClient mode only. Will try to connect to the server at server_ip. Defaults
\t\tto 127.0.0.1, localhost.

\t-h
\t\tDisplays help text and exits.

\t-v
\t\tDisplays version text and exits.

RETURN CODES
\tIf the command line arguments fail to parse, 1 will be returned. In server
\tmode, %s will not exit on it's own; no error codes will be returned. In
\tclient mode, %s will not exit on it's own under normal conditions. If it
\tfailed to connect, 2 will be returned. If there is no room on the server, or
\tinvalid data was recieved from the server, 3 will be returned.

AUTHOR
\tona li toki e jan Epiphany tawa mi.

BUGS
\tReport bugs to 
\t<https://github.com/ona-li-toki-e-jan-Epiphany-tawa-mi/netcatchat/issues>.

COPYRIGHT:
\tCopyright © 2023 ona li toki e jan Epiphany tawa mi. License: MIT. This is
\tfree software; you are free to modify and redistribute it. See the source
\tor visit <https://mit-license.org> for the full terms of the license. THIS
\tSOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND.

SEE ALSO:
\tGitHub repository:
\t<https://github.com/ona-li-toki-e-jan-Epiphany-tawa-mi/netcatchat>
" "$0" "$0" "$0" "$0" "$0" "$0" "$0" "$0" "$0" "$0" "$0"
}

print_version() {
    echo "$0 V0.1.0"
}

# The port that users connect to in order to get a port to chat on.
server_port=2000
# shellcheck disable=SC2207
# (server) The ports that each user uses to send and recieve messages.
client_ports=({2001..2011})
# (client) IP of the server to connect to.
server_ip=127.0.0.1
# either 'client' or 'server'.
type=client

while getopts 'sp:c:i:hv' flag; do
    # shellcheck disable=SC2206
    case "$flag" in
        s) type=server            ;;
        p) server_port="$OPTARG"  ;;
        c) client_ports=($OPTARG) ;;
        i) server_ip="$OPTARG"    ;;
        h) print_usage;   exit    ;;
        v) print_version; exit    ;;
        *) print_usage;   exit 1  ;;
    esac
done

option_parsing_failed='false'

if ! [[ "$server_port" =~ $port_regex ]]; then
    log_error "$0: invalid port $server_port specfied with argument -p"
    option_parsing_failed='true'
fi

for client_port in "${client_ports[@]}"; do
    if ! [[ "$client_port" =~ $port_regex ]]; then
        log_error "$0: invalid client_port specfied with argument -c"
        option_parsing_failed='true'
    fi
done

# If server_ip (-i) is invalid netcat will catch it.
if [ "$option_parsing_failed" = 'true' ]; then
    exit 1
fi



run_server() {
    temporary_directory=$(mktemp -d)
    # Array between client ports and their FIFOs for sending messages.
    client_input_fifos=()
    # Array between client ports and their FIFOs for recieving messages.
    client_output_fifos=()
    # A FIFO for the port distributor subprocess to recieve commands from.
    distributor_command_input_fifo="$temporary_directory/commandin"
    mkfifo "$distributor_command_input_fifo"



    trap '
        log_info "Shutting down..."

        rm -rf "$temporary_directory"

        pkill -P $$
        exit
    ' EXIT



    ##
    # Handles sending and recieving messages from an individual client port.
    # Will send the !free command to the port distributor when the client closes
    #   the connection to free up the port.
    #
    # Parameters:
    #   $1 - the client port to handle.
    #   $2 - the FIFO to send messages to the client with.
    #   $3 - the FIFO to recieve messages from the client with.
    #   
    handle_client_connection() {
        while true; do
            log_info "Started listening on port $1"
            echo "Welcome!, You are now chatting as: $1" > "$2" &
            netcat -l "$1" 0<> "$2" 1<> "$3"
            
            log_info "Connection opened and closed on port $1"
            echo "!free $1" > "$distributor_command_input_fifo" &

            for other_client_port in "${client_ports[@]}"; do
                if [ "$other_client_port" -ne "$1" ]; then
                    input_fifo="${client_input_fifos[$other_client_port]}"
                    echo "$1 has disconnected" 1<> "$input_fifo"
                fi
            done
        done
    }

    # Launch subprocess for each client port to handle the connection.
    for client_port in "${client_ports[@]}"; do
        input_fifo="$temporary_directory/messagein-$client_port"
        client_input_fifos["$client_port"]="$input_fifo"
        mkfifo "$input_fifo"
        output_fifo="$temporary_directory/messageout-$client_port"
        client_output_fifos["$client_port"]="$output_fifo"
        mkfifo "$output_fifo"
    done
    for client_port in "${client_ports[@]}"; do
        input_fifo="${client_input_fifos["$client_port"]}"
        output_fifo="${client_output_fifos["$client_port"]}"
        handle_client_connection "$client_port" "$input_fifo" "$output_fifo" & 
    done



    ##
    # Handles telling clients which ports are avalible.
    #
    distribute_ports() {
        avalible_ports=("${client_ports[@]}")
        active_ports=()
        # Used to store ports that have been distributed, but not connected to,
        #   so that they can be freed automatically if no one connects.
        active_port_timeout_map=()

        ##
        # Frees the given port for reuse.
        #
        # Parameters:
        #   $1 - the port to free.
        #
        free_port() {
            unset -v "active_ports[$1]"
            timeout="${active_port_timeout_map[$1]}"
            if [ "${#timeout}" -gt 0 ]; then
                unset -v "active_port_timeout_map[$1]"
            fi

            avalible_ports+=("$1")
        }

        while true; do
            # Temporarily stores the ports freed with !free.
            freed_ports=()
            # Temporarily stores the ports marked with !notimeout that do not
            #   have a timeout.
            timeoutless_notimeout_ports=()
            # Handles commands from other processes ran by this script.
            echo "" > "$distributor_command_input_fifo" & # Prevents blocking.
            while read -r line; do
                # shellcheck disable=SC2206
                command_arguments=($line)

                if [ "${#command_arguments[@]}" -ge 2 ]; then
                    port=${command_arguments[1]}

                    case "${command_arguments[0]}" in
                        # Frees ports that are no longer in use.
                        !free)
                            if [ "$port" = "${active_ports[$port]}" ]; then
                                free_port "$port"
                                log_info "Port $port was freed"

                                freed_ports["$port"]="$port"
                            else
                                log_error "Attempted to free inactive port $port!"
                            fi
                        ;;
                        # Prevents a used port from timing out.
                        !notimeout)
                            timeoutless_notimeout_ports["$port"]=$port

                            timeout="${active_port_timeout_map[$port]}"
                            if [ "${#timeout}" -gt 0 ]; then
                                unset -v "active_port_timeout_map[$port]"
                            fi
                        ;;
                    esac
                fi
            done < "$distributor_command_input_fifo"

            # If we got a !notimeout on an 'avalible' port, that means that 
            #   someone has connected to it without first connecting to the
            #   server port. Since the port is in use, we need to mark it as
            #   active.
            for notimeout_port in "${timeoutless_notimeout_ports[@]}"; do
                # Freed ports are guaranteed inactive.
                if [ "${#freed_ports[$notimeout_port]}" -gt 0 ]; then
                    continue
                fi

                was_port_locked='false'

                for (( i=0; i < ${#avalible_ports[@]}; ++i )); do
                    avalible_port=${avalible_ports[$i]}
                    if [ "$notimeout_port" = "$avalible_port" ]; then
                        was_port_locked='true'
                        unset -v 'avalible_ports[i]'; 
                        active_ports["$avalible_port"]="$avalible_port"

                        log_info "Found unexpected connection on port $avalible_port; marking as active"
                        break
                    fi
                done

                if [ "$was_port_locked" = 'true' ]; then
                    avalible_ports=("${avalible_ports[@]}")
                fi
            done

            # Frees ports that no one has connected to.
            for active_port in "${active_ports[@]}"; do
                timeout=${active_port_timeout_map[$active_port]}

                if [ "${#timeout}" -gt 0 ]; then
                    current_time=$(date +%s)
                    if (( current_time - timeout > 3 )); then
                        free_port "$active_port"
                        unset -v "active_port_timeout_map[$active_port]"
                        log_info "Timed out port $active_port"
                    fi
                fi
            done

            # Distributes ports.
            if [ "${#avalible_ports[@]}" -gt 0 ]; then
                port=${avalible_ports[0]}
                echo "$port" | netcat -l -w 0 "$server_port" > /dev/null
                
                log_info "Gave out port $port"
                unset -v 'avalible_ports[0]'; avalible_ports=("${avalible_ports[@]}")
                active_ports["$port"]="$port"
                active_port_timeout_map["$port"]=$(date +%s)

            else
                echo -1 | netcat -l -w 0 "$server_port"
                log_info 'Gave out port -1 to client to due all ports being used up'
            fi
        done
    }
    distribute_ports &



    # Handles sending messages between connected clients.
    while true; do
        for client_port in "${client_ports[@]}"; do
            output_fifo=${client_output_fifos[$client_port]}
            has_message='false'

            while read -r -t 0; do
                has_message='true'
                read -r line
                line=$(trim_whitespace "$line")

                if [ "${#line}" -gt 0 ]; then
                    message="[$client_port]: $line"
                    log_info "$message"

                    # Client message is sent back to them as confirmation.
                    for other_client_port in "${client_ports[@]}"; do
                        input_fifo="${client_input_fifos[$other_client_port]}"
                        echo "$message" 1<> "$input_fifo"
                    done
                fi
            done 0<> "$output_fifo"

            if [ "$has_message" = 'true' ]; then
                echo "!notimeout $client_port" > "$distributor_command_input_fifo" &
            fi
        done

        sleep 0.1
    done
}



run_client() {
    trap 'log_info "Shutting down..."' EXIT

    log_info "Connecting to $server_ip:$server_port..."
    port=$(netcat -v -w 1 "$server_ip" "$server_port")
    
    if [ "$port" = "" ]; then
        log_error "Could not connect to $server_ip:$server_port!"
        exit 2
    elif [ "$port" -eq -1 ]; then 
        log_error "No avalible client ports on $server_ip to connect to!"
        exit 3
    elif ! [[ "$port" =~ $port_regex ]]; then
        log_error "Recieved invald port $port from $server_ip:$server_port!"
        exit 3
    else
        log_info "Recieved port $port, reconnecting to $server_ip:$port..."
        { echo "CONNECTED" ; cat ; } | trim_whitespace_stdin | netcat -v "$server_ip" "$port"
    fi
}



if [ "$type" = "server" ]; then
    run_server
elif [ "$type" = "client" ]; then
    run_client
else
    log_error "Unknown run type '$type'!"
    exit 1
fi