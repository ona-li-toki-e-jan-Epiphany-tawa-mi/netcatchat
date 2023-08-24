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
#TODO Create client.
#TODO Create client port distributor.
#TODO Make use system user name.



# Associative array between client ports and their FIFOs for sending messages.
client_input_fifos=()
# Associative array between client ports and FIFOs for recieving messages.
client_output_fifos=()



trap '
    rm "${client_input_fifos[@]}" "${client_output_fifos[@]}"

    pkill -P $$
    exit
' INT



# TODO document this.
handle_client_connection() {
    while true; do
        echo "Started listening on port $1"
        # Routing black magic to prevent read/writes with the FIFOs from 
        #   blocking.
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
done