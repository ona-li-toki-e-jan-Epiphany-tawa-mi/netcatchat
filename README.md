# netcatchat

netcatchat is a simple command-line chat server and client using netcat.

Each client on the server is identified simply with what port they are connected
on; no usernames.

No messages are saved to disk, just kept in memory. Keep in mind that these are
not garbage collected; if you're running a server consider having it restart
every-so-often.

## How to run

Dependencies:

- Bash.
- netcat (OpenBSD implementation recommended.)

There's a `flake.nix` you can use to generate a development enviroment with
`nix develop path:.`.

Then, run the following command(s) to get started:

```
./netcatchat.sh -h
```

Note that running netcatchat as a server will not work if netcat will not accept
a wait time of 0, which depends on which implementation is installed on your
system. To check if you can run a server, run the following netcat command:

```console
nc -l -w 0
```

If it immediately exits and ouputs something like "Error: Invalid wait-time: 0",
you will not be able to run netcatchat in server mode. The client should still
work though.

## Installation

You can install it with Nix from the NUR (https://github.com/nix-community/NUR)
with the following attribute:

```nix
nur.repos.ona-li-toki-e-jan-Epiphany-tawa-mi.netcatchat
```

## paltepuk netcatchat server

I have a netcatchat server running on my paltepuk server, which you can connect
to at `6ay2f2mmkogzz6mwcaxjttxl4jydnskavfaxgumeptwhhdjum3i6n3id.onion` port
2000. To access it, you can use the following command as a template. This
assumes you have the Tor daemon running on localhost on port 9050, change for
your setup. It has room for 25 people.

```
netcatchat -x 127.0.0.1:9050 -i 6ay2f2mmkogzz6mwcaxjttxl4jydnskavfaxgumeptwhhdjum3i6n3id.onion
```

Keep in mind that the chat is COMPLETELY UNMODERATED. I take
absolutely no responsibility for what people say on it. Proceed at your own
risk.

The server will reset every 4 hours and any messages will be wiped.
