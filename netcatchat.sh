#!/usr/bin/env bash

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



#TODO Add description.
print_usage() {
    printf "NAME
\t%s - simple chat server and client using netcat

SYNOPSIS
\t%s -h
\t%s -v
\t%s [-p server_port] [-i server_ip]
\t%s -s [-p server_port] [-c client_ports]

DESCRIPTION
\tTODO

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
" "$0" "$0" "$0" "$0" "$0" "$0" "$0" "$0" "$0" "$0"
}

print_version() {
    echo "$0 V0.1.0"
}

# The port that users connect to in order to get a port to chat on.
server_port=2000
# shellcheck disable=SC2207
# (server) The ports that each user uses to send and recieve messages.
client_ports=($(seq 2001 2010))
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
    # Array between client ports and their FIFOs for sending messages.
    client_input_fifos=()
    # Array between client ports and their FIFOs for recieving messages.
    client_output_fifos=()
    # A FIFO for the port distributor subprocess to recieve commands from.
    distributor_command_input_fifo='commandin'; mkfifo "$distributor_command_input_fifo"



    trap '
        log_info "Shutting down..."

        rm "${client_input_fifos[@]}" "${client_output_fifos[@]}" "$distributor_command_input_fifo"

        pkill -P $$
        exit
    ' INT



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
        input_fifo="messagein-$client_port"; client_input_fifos["$client_port"]="$input_fifo"
        mkfifo "$input_fifo"
        output_fifo="messageout-$client_port"; client_output_fifos["$client_port"]="$output_fifo"
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

        while true; do
            echo "" > "$distributor_command_input_fifo" & # Prevents blocking.
            # Frees ports that are no longer in use.
            while read -r line; do
                # shellcheck disable=SC2206
                command_arguments=($line)

                if [ "${#command_arguments[@]}" -ge 2 ] && [ "${command_arguments[0]}" = '!free' ]; then
                    port=${command_arguments[1]}

                    if [ "$port" = "${active_ports[$port]}" ]; then
                        log_info "Port $port was freed"

                        unset -v "active_ports[$port]"
                        avalible_ports+=("$port")
                    else
                        log_error "Attempted to free inactive port $port!"
                    fi
                fi
            done < "$distributor_command_input_fifo"

            # Distributes ports.
            if [ "${#avalible_ports[@]}" -gt 0 ]; then
                port="${avalible_ports[0]}"
                echo "$port" | netcat -l -w 0 "$server_port" > /dev/null
                
                log_info "Gave out port $port"
                unset -v 'avalible_ports[0]'; avalible_ports=("${avalible_ports[@]}")
                active_ports["$port"]="$port"

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
            output_fifo="${client_output_fifos[$client_port]}"

            while read -r -t 0; do
                read -r line
                message="[$client_port]: $line"
                log_info "$message"

                # Client message is sent back to them as confirmation.
                for other_client_port in "${client_ports[@]}"; do
                    input_fifo="${client_input_fifos[$other_client_port]}"
                    echo "$message" 1<> "$input_fifo"
                done
            done 0<> "$output_fifo"
        done

        sleep 0.1
    done
}



run_client() {
    trap 'log_info "Shutting down..."' INT

    log_info "Connecting to $server_ip:$server_port..."
    port=$(netcat -v -w 0 "$server_ip" "$server_port")
    
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
        { echo "CONNECTED" ; cat ; } | netcat -v "$server_ip" "$port"
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