#!/usr/bin/env bash

################################################################################
# Config START                                                                 #
################################################################################
server_port=2000
# shellcheck disable=SC2207
client_ports=($(seq 2001 2010))
################################################################################
# Config END                                                                   #
################################################################################

#TODO Create proper CLI.
#TODO Make use system user name.


run_server() {
    # Associative array between client ports and their FIFOs for sending messages.
    client_input_fifos=()
    # Associative array between client ports and FIFOs for recieving messages.
    client_output_fifos=()



    trap '
        echo "Shutting down..."

        rm "${client_input_fifos[@]}" "${client_output_fifos[@]}"

        pkill -P $$
        exit
    ' INT



    # TODO document this.
    handle_client_connection() {
        while true; do
            echo "Started listening on port $1"
            netcat -l "$1" 0<> "$2" 1<> "$3"
            echo "Connection opened and closed on port $1"

            # TODO Sometimes dosen't work for some reason.
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

        handle_client_connection "$client_port" "$input_fifo" "$output_fifo" & 
    done



    # TODO Figure out way to tell if connections reopen.
    # Handles telling clients which ports are avalible.
    distribute_ports() {
        avalible_ports=("${client_ports[@]}")
        active_ports=()

        while true; do
            if [ "${#avalible_ports[@]}" -gt 0 ]; then
                port="${avalible_ports[0]}"
                echo "$port" | netcat -l -w 0 "$server_port" > /dev/null
                
                echo "Gave out port $port"
                unset -v 'avalible_ports[0]'; avalible_ports=("${avalible_ports[@]}")
                active_ports+=("$port")

            else
                echo -1 | netcat -l -w 0 "$server_port"
            fi
        done
    }
    distribute_ports &



    # Handles sending messages between connected clients.
    while true; do
        for client_port in "${client_ports[@]}"; do
            output_fifo="${client_output_fifos[$client_port]}"

            if read -r -t 0; then
                read -r line
                message="[$client_port]: $line"
                echo "$message"

                for other_client_port in "${client_ports[@]}"; do
                    if [ "$client_port" -ne "$other_client_port" ]; then
                        input_fifo="${client_input_fifos[$other_client_port]}"
                        echo "$message" 1<> "$input_fifo"
                    fi
                done
            fi 0<> "$output_fifo"
        done

        sleep 0.1
    done
}



run_client() {
    #TODO add way to choose ip.
    echo "Connecting to 127.0.0.1:$server_port..."
    port=$(netcat -w 0 127.0.0.1 "$server_port" -v)
    echo "Recieved port $port, reconnecting to 127.0.0.1:$port..."
    netcat 127.0.0.1 "$port" -v
}



# TODO command line stuff with getopts to handle selecting type.
if [ "$1" = "server" ]; then
    run_server
elif [ "$1" = "client" ]; then
    run_client
fi