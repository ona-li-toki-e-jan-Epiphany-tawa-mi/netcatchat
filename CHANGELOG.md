# Changelog

## Upcoming

- Relicensed as GPLv3+ (was MIT.)
- Removed mentions of I2P and stunnel in help info since I don't know if they would work.
- Added `-l` option.

## 1.0.0

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

## 0.1.2

- Added proxies.
- Made '-w 0' behavior across netcat implementations clear.

## 0.1.1

- Intial release.
