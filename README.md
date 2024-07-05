# netcatchat

netcatchat is a simple command-line chat server and client for Linux using netcat.

Each client on the server is identified simply with what port they are connected
on; no usernames.

No messages are saved to disk, just kept in memory. Keep in mind that these are
not garbage collected; if you're running a server consider having it restart
every-so-often.

## paltepuk netcatchat server

I have a netcatchat server running on my paltepuk server, which you can connect
to at `6ay2f2mmkogzz6mwcaxjttxl4jydnskavfaxgumeptwhhdjum3i6n3id.onion` port
2000. To access it, you can use the following command as a template. This
assumes you have the Tor daemon running on localhost on port 9050, change for
your setup. It has room for 25 people.

Keep in mind that the chat is COMPLETELY UNMODERATED. I take
absolutely no responsibility for what people say on it. Proceed at your own
risk.

The server will reset every 4 hours and any messages will be wiped.

```
netcatchat -x 127.0.0.1:9050 -i 6ay2f2mmkogzz6mwcaxjttxl4jydnskavfaxgumeptwhhdjum3i6n3id.onion
```

## Forewarnings

This chat system is extremely basic, and I do not plan to extended it. It will
not check if multiple clients are connected from the same ip. It will not block
or rate-limit spammers. Someone could easily use a script to steal all the ports
and prevent people from connecting. There is absolutely no mechanism for
moderation. No attempts are made at encryption. Basically, proceed with caution.

netcatchat CAN be used with a proxy though, so you can achieve encryption
through the use of Tor or other anonymizing networks. Or, you could perhaps use
stunnel or something similar to make an SSL tunnel to use.

There is the possiblity for someone to make their own script to connect to the
server_port and not reconnect on a client port, or connect directly to a client
port. There are checks in place to make sure that ports dished out from the
server_port are freed if unused and locked (as-in it won't try to give someone
that port to connect on as it is busy) if someone decides to directly connect to
a client port, so such "attacks" should not be too big of an issue.

## Dependencies

netcatchat requires netcat and the bash shell.

There's a `flake.nix` you can use to generate a development enviroment with
`nix develop path:.`.

Note that running netcatchat as a server will not work if netcat will not accept
a wait time of 0, which depends on which implementation is installed on your
system. To check if you can run a server, run the following netcat command:

```console
nc -l -w 0
```

If it immediately exits and ouputs something like "Error: Invalid wait-time: 0",
you will not be able to run netcatchat in server mode. The client should still
work though.

From my experience, the OpenBSD implementation works best.

## Installation

netcatchat is just a single shell script, but you can also install it with Nix
from the NUR (https://github.com/nix-community/NUR) with the following
attribute:

```nix
nur.repos.ona-li-toki-e-jan-Epiphany-tawa-mi.netcatchat
```

## Synopsis

netcatchat -h

netcatchat -v

netcatchat [-p server_port] [-i server_ip] [-x proxy_address[:port] [-X proxy_protocol]]

netcatchat -s [-p server_port] [-c client_ports]

## Options

- -s

By default, netcatchat will run in client mode and try to connect to a server.
Specifying -s will, instead, make it run in server mode.

- -p server_port

In server mode, netcatchat will listen on server_port for incoming chat clients
and routes them to a client port if one is avalible. On client mode, netcatchat
will try to connect to the server on server_port to figure out which client port
to connect on. Defaults to 2000

- -c client_ports

Server mode only. client_ports are the avalible ports for clients to connect on.
Each client needs their own port, so the maximum number of users will be limited
by how many are supplied. Defaults to 2001-2010 (inclusive.)

- -i server_ip

Client mode only. Will try to connect to the server at server_ip. Defaults to
127.0.0.1, localhost.

- -X proxy_protocol

Client mode only. The protocol to use for the proxy. Must be either: 4 - SOCKS4,
5 - SOCKS5, or connect - HTTPS. SOCKS5 is used by default if not specified. Must
be used with -x.

- -x proxy_address

Client mode only. The address of the proxy to use.

- -h

Displays help text and exits.

- -v

Displays version text and exits.

## Return Codes

If the command line arguments fail to parse, 1 will be returned. In server mode,
netcatchat will not exit on it's own; no error codes will be returned. In client
mode, netcatchat will not exit on it's own under normal conditions. If it failed
to connect, 2 will be returned. If there is no room on the server, or invalid
data was recieved from the server, 3 will be returned.
