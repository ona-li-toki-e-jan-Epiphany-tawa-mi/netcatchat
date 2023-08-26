# netcatchat

NOTE: not finished yet

netcatchat is a simple command-line chat server and client for Linux using netcat.

This chat system is extremely basic, and I do not plan to extended it. It will not check if multiple clients are connected from the same ip. It will not block or rate-limit spammers. Someone could easily use a script to steal all the ports and prevent people from connecting. There is absolutely no mechanism for moderation. No attempts are made at encryption. Basically, proceed with caution.

Each client on the server is identified simply with what port they are connected on; no usernames.

There is the possiblity for someone to make their own script to connect to the server_port and not reconnect on a client port, or connect directly to a client port. There are checks in place to make sure that ports dished out from the server_port are freed if unused and locked (as-in it won't try to give someone that port to connect on as it is busy) if someone decides to directly connect to a client port, so such "attacks" should not be too big of an issue.

I'm considering renting a server/simillar and tossing a netcatchat server on it to run 24/7. If I do, I will put the IP and server port here.

## Installation

netcatchat is just a standalone bash script; you can run it as-is. If you want to run it from the command line from anywhere just by typing "netcatchat", run the following commands on the script file:

```console
sudo cp netcatchat.sh /usr/local/bin/netcatchat
sudo chown root:root /usr/local/bin/netcatchat
sudo chmod u=w,a+rx /usr/local/bin/netcatchat
```

## Synopsis

netcatchat -h

netcatchat -v

netcatchat [-p server_port] [-i server_ip]

netcatchat -s [-p server_port] [-c client_ports]

## Options

- -s

By default, netcatchat will run in client mode and try to connect to a server. Specifying -s will, instead, make it run in server mode.

- -p server_port

In server mode, netcatchat will listen on server_port for incoming chat clients and routes them to a client port if one is avalible. On client mode, netcatchat will try to connect to the server on server_port to figure out which client port to connect on. Defaults to 2000

- -c client_ports

Server mode only. client_ports are the avalible ports for clients to connect on. Each client needs their own port, so the maximum number of users will be limited by how many are supplied. Defaults to 2001-2010 (inclusive.)

- -i server_ip

Client mode only. Will try to connect to the server at server_ip. Defaults to 127.0.0.1, localhost.

- -h

Displays help text and exits.

- -v

Displays version text and exits.

## Return Codes

If the command line arguments fail to parse, 1 will be returned. In server mode, netcatchat will not exit on it's own; no error codes will be returned. In client mode, netcatchat will not exit on it's own under normal conditions. If it failed to connect, 2 will be returned. If there is no room on the server, or invalid data was recieved from the server, 3 will be returned.