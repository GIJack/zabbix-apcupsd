#!/usr/bin/env bash

# I pulled out wireshark and reversed the apcupsd command, and was able to
# recreate it with a shell script, thinking I could remove the need of having
# apcaccess running locally if it the battery was on a remote host, and use
# standard system commands. Turns out that this only works in bash, only works
# with openbsd-netcat, and is much more limited then binary apcaccess. But here
# it is.

UPS_HOST=127.0.0.1
UPS_PORT=3551
_apcaccess() {
  printf "\x00\x06status" | nc -N ${UPS_HOST} ${UPS_PORT} | tr -cd '\11\12\15\40-\176' | tr -d ")\'+"
}
