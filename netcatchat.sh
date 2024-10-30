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

# TODO? add proper TUI.
# TODO? add configurable MOTD.

# Error on unset variables.
set -u


################################################################################
# Global START                                                                 #
################################################################################

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

# Filters out special characters (except newlines) from stdin.
filter_message() {
    while read -r line; do
        echo "$line" | LC_ALL=C tr -c '[:print:]\n' ' '
    done
}

################################################################################
# Global END                                                                   #
################################################################################



################################################################################
# Argument parsing START                                                       #
################################################################################

# Matches an extended regular expression (ERE) against a string.
# $1 - the ERE.
# $2 - the string to match against.
# $? - 0 if the string matches, else 1.
match_regex() {
    # Setting POSIXLY_CORRECT can disable implementation-specfic extensions and
    # behaviors.
    POSIXLY_CORRECT='' grep -E "$1" <<< "$2" > /dev/null
    return $?
}

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
  or I2P (http).

  netcatchat will not run in server mode if the system's netcat implementation
  cannot accept a wait time of 0, which depends on which implementation is
  installed on your system. This check is preformed automatically on startup,
  but you can aslo manually check check by running 'nc -l -w 0 -p <port>'. If
  this immediately returns, instead of waiting for input, you cannot run
  netcatchat in server mode. Client mode should still work.

  OpenBSD's implementation of netcat is recommended.

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
    (client mode) The protocol to use for the proxy. Requires '-x'.
    Must one of: 'socks4', 'socks5', or 'http'.

  -x proxy_address[:port]
    (client mode) Proxy address. Requires '-X'.
    If the port is not specified, it defaults to 3128 for 'http' and 1080 for
    'socks4' and 'socks5'

  -h
    Displays usage and exits.

  -v
    Displays version and exits.

Exit status:
  Under normal operation, netcatchat, whether client or server, will not exit on
  it's own.

  1 - some error occurred.
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
# Whether to use a proxy.
use_proxy='false'

# Parsing.
[ 0 -eq $# ] && usage && exit
while getopts 'sp:c:i:X:x:hv' flag; do
    case "$flag" in
        # Global options.
        s) mode=server              ;;
        p) server_port="$OPTARG"    ;;
        # Server options.
        c) client_ports="$OPTARG"   ;;
        # Client options.
        i) server_address="$OPTARG" ;;
        X) proxy_protocol="$OPTARG" ;;
        x) proxy_address="$OPTARG"  ;;
        # Other.
        h) usage;       exit        ;;
        v) version;     exit        ;;
        *) short_usage; exit 1      ;;
    esac
done
if [ -n "$proxy_protocol" ] || [ -n "$proxy_address" ]; then
    use_proxy='true'
fi

## Validation.
port_regex='[[:digit:]]{1,5}'
# Global options.
if ! match_regex "^$port_regex\$" "$server_port"; then
    short_usage
    fatal "invalid server_port '$server_port' supplied with '-p'; expected port number"
fi
# Server options.
if [ 'server' == "$mode" ]; then
    if ! match_regex "^$port_regex( $port_regex)*\$" "$client_ports"; then
        short_usage
        fatal "invalid client_ports '$client_ports' supplied with -c; expected space-seperated list of port numbers"
    fi
fi
# Client options.
if [ 'client' == "$mode" ]; then
    if [ -z "$server_address" ]; then
        short_usage
        fatal "'-i' was not specified or an empty server_address was supplied"
    fi
    if [ 'true' == "$use_proxy" ]; then
        if [ -z "$proxy_address" ]; then
            short_usage
            fatal "'-x' was not specified or an empty proxy_address was supplied"
        fi
        if [ 'socks4' != "$proxy_protocol" ] && [ 'socks5' != "$proxy_protocol" ] &&
               [ 'http' != "$proxy_protocol" ]; then
        short_usage
        fatal "invalid proxy_portocol '$proxy_protocol' supplied with '-X': expected one of: 'socks4', 'socks5', 'http'"
        fi
    fi
fi

################################################################################
# Argument parsing END                                                         #
################################################################################



################################################################################
# Client START                                                                 #
################################################################################

if [ 'client' == "$mode" ]; then
    # Converts the proxy protocol names netcatchat uses to those that netcat
    # uses.
    nc_proxy_protocol=
    if [ 'true' == "$use_proxy" ]; then
        info "using $proxy_protocol proxy '$proxy_address'"

        case "$proxy_protocol" in
            'http')   nc_proxy_protocol='connect' ;;
            'socks4') nc_proxy_protocol='4'       ;;
            'socks5') nc_proxy_protocol='5'       ;;
            *)        fatal "unreachable"         ;;
        esac
    fi

    info "obtaining client port from $server_address:$server_port..."
    client_port=
    if [ 'true' == "$use_proxy" ]; then
        client_port=$(nc -v -w 1 -X "$nc_proxy_protocol" -x "$proxy_address" "$server_address" "$server_port")
    else
        client_port=$(nc -v -w 1 "$server_address" "$server_port")
    fi

    if [ "$client_port" = '' ]; then
        fatal "could not connect to $server_address:$server_port"
    elif [ "$client_port" -eq -1 ]; then
        fatal "no available client ports on $server_address:$server_port to connect to"
    elif ! match_regex '^[[:digit:]]{1,5}$' "$client_port"; then
        fatal "recieved invald port $client_port from $server_address:$server_port"
    else
        info "recieved port $client_port, reconnecting to $server_address:$client_port..."

        # The initial message indicates that the user joined, and also prevents
        # the server from timing out the port.
        intial_message='CONNECTED'

        if [ 'true' == "$use_proxy" ]; then
            { echo "$intial_message"; cat; } | filter_message |                     \
                nc -v -X "$nc_proxy_protocol" -x "$proxy_address" "$server_address" \
                   "$client_port" | filter_message
        else
            { echo "$intial_message"; cat; } | filter_message | \
                nc -v "$server_address" "$client_port" | filter_message
        fi
    fi
fi

################################################################################
# Client END                                                                   #
################################################################################



################################################################################
# Server START                                                                 #
################################################################################

# Tests if the port can be opened by netcat. If not, netcatchat will crash.
test_port() {
    # If netcat could not open the port, this will exit immediately.
    timeout 0.25 nc -l "$1" > /dev/null 2>&1
    [ 124 -ne $? ] && fatal "unable to open port '$1'"
}

# Echoes the first supplied argument to stdout.
# Echoes nothing when supplied no arguments.
head() {
    [ 0 -lt $# ] && echo "$1"
}
# Echoes every argument except the first as a space seprated list.
# Echoes nothing when supplied 0 or 1 arguments.
# Error on empty list.
tail() {
    if [ 1 -lt $# ]; then
        shift
        echo "$*"
    fi
}
# Echoes every argument as a space seperated list.
concat() {
    echo "$*"
}

# Kills all spawned subprocesses.
kill_subprocesses() {
    jobs="$(jobs -p)"
    # shellcheck disable=2086 # We want word splitting.
    [ -n "$jobs" ] && kill $jobs 2>/dev/null
}
# Waits until all subprocesses, at the time of calling, terminate.
join_subprocesses() {
    jobs="$(jobs -p)"
    # shellcheck disable=2086 # We want word splitting.
    [ -n "$jobs" ] && wait $jobs 2>/dev/null
}

# Runs the port-distribution process on the server port.
# Does not return.
# $1 - command input fifo. Used to recieve commands from client port handlers.
handle_server_port() {
    command_fifo="$1"

    free_ports="$client_ports"
    ports_timeout_map=

    info "server port: started listening"

    while true; do
        # Distributes out free client ports to incoming clients.
        if [ -n "$free_ports" ]; then
            # shellcheck disable=2086 # We want word splitting.
            port="$(head $free_ports)"
            # shellcheck disable=2086 # We want word splitting.
            free_ports="$(tail $free_ports)"

            test_port "$server_port"
            echo "$port" | nc -l -w 0 "$server_port" > /dev/null

            info "server port: gave out port '$port' to incoming client"
            # shellcheck disable=2086 # We want word splitting.
            ports_timeout_map="$(concat $ports_timeout_map "$port=$(date +%s)")"
        else
            test_port "$port"
            # -1 indicates that there are no ports left.
            echo '-1' | nc -l -w 0 "$server_port" > /dev/null
            info "server port: did not give out port to incoming client; none are free"
        fi

        # List of ports that sent a !notimeout command (which means something is
        # connected) but are marked as free.
        unexpectedly_active_ports=

        # Handles commands from other subprocesses.
        echo "" > "$command_fifo" & # Prevents blocking.
        while read -r line; do
            # shellcheck disable=2086 # We want word splitting.
            command="$(head $line)"
            # shellcheck disable=2086 # We want word splitting.
            line="$(tail $line)"
            # shellcheck disable=2086 # We want word splitting.
            argument="$(head $line)"

            if [ -n "$command" ] && [ -n "$argument" ]; then
                case "$command" in
                    # Marks ports that are no longer active as free.
                    # $1 - port to free.
                    !free)
                        info "server port: marked port '$argument' as free"
                        # shellcheck disable=2086 # We want word splitting.
                        free_ports="$(concat $free_ports "$argument")"
                        ;;

                    # Prevents a ports that were given out from timing out.
                    # $1 - port to stop from timing out.
                    !notimeout)
                        had_timeout='false'

                        if [ -n "$ports_timeout_map" ]; then
                            new_ports_timeout_map=

                            for port_time in $ports_timeout_map; do
                                old_IFS="$IFS"; IFS='='
                                # shellcheck disable=2086 # We want word splitting.
                                port="$(head $port_time)"
                                IFS="$old_IFS"

                                if [ "$argument" -ne "$port" ]; then
                                    # shellcheck disable=2086 # We want word splitting.
                                    new_ports_timeout_map="$(concat $new_ports_timeout_map "$port=$time")"
                                else
                                    had_timeout='true'
                                fi
                            done

                            ports_timeout_map="$new_ports_timeout_map"
                        fi

                        if [ 'false' == "$had_timeout" ]; then
                            for port in $free_ports; do
                                if [ "$argument" -eq "$port" ]; then
                                    # shellcheck disable=2086 # We want word splitting.
                                    unexpectedly_active_ports="$(concat $unexpectedly_active_ports "$argument")"
                                    break
                                fi
                            done
                        fi
                        ;;

                    *) fatal "unreachable" ;;
                esac
            fi
        done < "$command_fifo"

        # If we got !notimeout on a 'free' port, that means that something has
        # connected to it without first connecting to the server port. Since the
        # port is in use, we need to mark it as such.
        if [ -n "$unexpectedly_active_ports" ]; then
            for port in $unexpectedly_active_ports; do
                warn "server port: unexpected connection on client port '$port'; marking as active"

                new_free_ports=
                for free_port in $free_ports; do
                    if [ "$port" -ne "$free_port" ]; then
                        # shellcheck disable=2086 # We want word splitting.
                        new_free_ports="$(concat $new_free_ports "$free_port")"
                    fi
                done
                free_ports="$new_free_ports"
            done
        fi

        # Frees ports that have been given out but no client has connected to.
        # TODO make port timeout configurable.
        if [ -n "$ports_timeout_map" ]; then
            new_ports_timeout_map=

            for port_time in $ports_timeout_map; do
                old_IFS="$IFS"; IFS='='
                # shellcheck disable=2086 # We want word splitting.
                port="$(head $port_time)"
                # shellcheck disable=2086 # We want word splitting.
                time="$(tail $port_time)"
                IFS="$old_IFS"

                current_time=$(date +%s)
                if (( current_time - time > 3 )); then
                    # shellcheck disable=2086 # We want word splitting.
                    free_ports="$(concat $free_ports "$port")"
                    info "server port: timed out port '$port'"
                else
                    # shellcheck disable=2086 # We want word splitting.
                    new_ports_timeout_map="$(concat $new_ports_timeout_map "$port=$time")"
                fi
            done

            ports_timeout_map="$new_ports_timeout_map"
        fi
    done
}

# Converts a client port into an input FIFO path.
# $1 - the directory the FIFO should be in.
# $2 - the client port.
client_port_to_input_fifo() {
    echo "$1/client_port_${2}_input_fifo"
}
# Converts a client port into an output FIFO path.
# $1 - the directory the FIFO should be in.
# $2 - the client port.
client_port_to_output_fifo() {
    echo "$1/client_port_${2}_output_fifo"
}

# Runs the process to handle and individual client on a client port.
# Does not return.
# $1 - the port to handle.
# $2 - the temporary directory with the client port input/output FIFOs.
# $3 - the server port's command input fifo. Used to send commands to the server
#      port handler
handle_client_port() {
    port="$1"
    tmp="$2"
    server_port_command_fifo="$3"

    input_fifo="$(client_port_to_input_fifo "$tmp" "$port")"
    output_fifo="$(client_port_to_output_fifo "$tmp" "$port")"

    while true; do
        info "client port $port: started listening"
        echo "[server] Welcome!, You are now chatting as: $port" > "$input_fifo" &
        test_port "$port"
        nc -l "$port" 0<> "$input_fifo" 1<> "$output_fifo"

        info "client port $port: connection closed"
        echo "!free $port" > "$server_port_command_fifo" &

        for other_port in $client_ports; do
            if [ "$port" -ne "$other_port" ]; then
                other_input_fifo="$(client_port_to_input_fifo "$tmp" "$other_port")"
                echo "[server]: $1 has disconnected" 1<> "$other_input_fifo"
            fi
        done
    done
}

# Runs the proccess to handle routing chat messages between the client handlers.
# $1 - the temporary directory with the client port input/output FIFOs.
# $2 - the server port's command input fifo. Used to send commands to the server
#      port handler
handle_message_routing() {
    tmp="$1"
    server_port_command_fifo="$2"

    while true; do
        for port in $client_ports; do
            output_fifo="$(client_port_to_output_fifo "$tmp" "$port")"

            # Some cursed logic to read with timeout.
            # Extra tr to filter out excess newlines.
            output="$(timeout 0.1 cat 0<> "$output_fifo" | filter_message | LC_ALL=C tr '\n' ' ')"
            if [ -n "$output" ]; then
                message="[$port]: $output"
                info "$message"

                # Client message is sent back to them as confirmation.
                for other_port in $client_ports; do
                    input_fifo="$(client_port_to_input_fifo "$tmp" "$other_port")"
                    echo "$message" 1<> "$input_fifo"
                done

                # Prevents port from timing out since a client is using it.
                echo "!notimeout $port" > "$server_port_command_fifo" &
            fi
        done

        sleep 0.1
    done
}

if [ 'server' == "$mode" ]; then
    info "starting server..."

    info "testing netcat compatibility..."
    test_port "$server_port"
    # If '-w 0' works, this command should wait for input. If not, it will exit
    # immediately.
    timeout 0.25 nc -l -w 0 "$server_port" > /dev/null 2>&1
    [ 124 -ne $? ] && fatal "the available netcat implementation does not support a wait time of 0. Have you tried the OpenBSD implementation?"

    trap '
        info "cleaning up..."
        kill_subprocesses
        [ -n "$tmp" ] && rm -r "$tmp"

        info "shutting down..."
    ' EXIT

    info "setting up interprocess communication..."
    if ! tmp="$(mktemp -d)"; then
        fatal "unable to create directory with mktemp"
    fi
    server_port_command_fifo="$tmp/server_port_command_fifo"
    if ! mkfifo "$server_port_command_fifo"; then
        fatal "unable to create FIFO $server_port_command_fifo"
    fi
    for port in $client_ports; do
        input_fifo="$(client_port_to_input_fifo "$tmp" "$port")"
        if ! mkfifo "$input_fifo"; then
            fatal "unable to create FIFO $input_fifo"
        fi
        output_fifo="$(client_port_to_output_fifo "$tmp" "$port")"
        if ! mkfifo "$output_fifo"; then
            fatal "unable to create FIFO $input_fifo"
        fi
    done

    info "spawning subprocesses..."
    handle_server_port "$server_port_command_fifo" &
    for port in $client_ports; do
        handle_client_port "$port" "$tmp" "$server_port_command_fifo" &
    done
    handle_message_routing "$tmp" "$server_port_command_fifo" &

    # Wait for subproccesses to start up to log as started.
    sleep 1
    info "server started"
    join_subprocesses
fi

################################################################################
# Server END                                                                   #
################################################################################
