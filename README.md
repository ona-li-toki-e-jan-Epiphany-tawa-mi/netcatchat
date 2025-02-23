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
`nix develop`.

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
with a proxy that provides encryption, such as Tor (socks5.)

Only printable ASCII characters are supported. Anything that is not in [:print:]
(see 'man tr') will be filtered out by both the server and clients.

## Installation

You can install it with Nix from my personal package repository
[https://paltepuk.xyz/cgit/epitaphpkgs.git/about](https://paltepuk.xyz/cgit/epitaphpkgs.git/about).
