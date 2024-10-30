# netcatchat

A simple chat server and client that interfaces with netcat

In client mode, netcatchat will attempt to connect to a netcatchat server. If
successful, you will join and your name will be set to the port you're on.

In server mode, netcatchat will listen for and accept incoming netcatchat
clients and route messages between them.

## How to run

Dependencies:

- POSIX shell interpreter (i.e. bash, dash, sh.)
- netcat (OpenBSD implementation recommended.)
- GNU coreutils (or compatible alternative.)

There's a `flake.nix` you can use to generate a development enviroment with
`nix develop path:.`.

Then, run the following command(s) to get started:

```sh
./netcatchat.sh -h
```

Note that running netcatchat as a server will not work if netcat will not accept
a wait time of 0, which depends on the implementation is installed on your
system. To check if you can run a server, run the following netcat command:

```sh
nc -l -w 0 -p <port>
```

The server will also automatically run this test. If it immediately exits, you
will not be able to run netcatchat in server mode. The client should still work
though.

## How to test

Dependencies:

- shellcheck.

There is a `flake.nix` you can use with `nix develop path:.` to generate a
development enviroment.

Then, run the following command(s):

```sh
shellcheck netcatchat.sh
```


## Forewarnings

netcatchat is extremely basic; it does not come with chat filtering, protections
against spamming, banning users, or any other fancy business.

netcatchat does not provide encryption in of itself. It can, however, be used
with a proxy that provides encryption, such as stunnel (http), Tor (socks5), or
I2P (http).

Only printable ASCII characters are supported. Anything that is not in [:print:]
(see 'man tr') will be filtered out by both the server and clients.

## Installation

You can install it with Nix from the NUR
([https://github.com/nix-community/NUR](https://github.com/nix-community/NUR))
with the following attribute:

```nix
nur.repos.ona-li-toki-e-jan-Epiphany-tawa-mi.netcatchat
```

## paltepuk netcatchat server

I have a netcatchat server running on my paltepuk webserver, which you can
connect to at `6ay2f2mmkogzz6mwcaxjttxl4jydnskavfaxgumeptwhhdjum3i6n3id.onion`
port 2000. To access it, you can use the following command as a template. This
assumes you have the Tor daemon running and it's SOCKSv5 proxy is available on
port 9050, modify for your setup. It has room for 25 people.

```
./netcatchat.sh -X socks5 -x 127.0.0.1:9050 -i 6ay2f2mmkogzz6mwcaxjttxl4jydnskavfaxgumeptwhhdjum3i6n3id.onion -p 2000
```

Keep in mind that the chat is COMPLETELY UNMODERATED. I take absolutely no
responsibility for what people say on it. Proceed at your own risk.

The server will reset every 4 hours and any messages will be wiped.

## Release notes

- Complete rewrite.
- Removed dependency on Bash, now should work with any (modernish) POSIX shell interpreter (tested with `bash --posix` and `dash`.
- Removed depedency on procps functions (`pkill`, `pgrep`, etc..).
- Vastly improved error handling.
- Added ability to set server MOTD.
- Added ability to set server port timeout.
- Added automatic test for netcat compatibility.
- More descriptive and useful logging and error messages.
- Made usage information (running with `-h`) easier to read.
- Improved filtering of control characters from chat messages (however only ASCII is supported now.)
- Removed default values for the `-i`, `-p`, `-X`, and `-c` CLI options (now must be explicitly specified.)
