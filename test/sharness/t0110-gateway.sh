#!/bin/sh
#
# Copyright (c) 2015 Matt Bell
# MIT Licensed; see the LICENSE file in this repository.
#

test_description="Test HTTP Gateway"

. lib/test-lib.sh

test_init_ipfs
test_config_ipfs_gateway_readonly $ADDR_GWAY
test_launch_ipfs_daemon

port=$PORT_GWAY
apiport=$PORT_API

# TODO check both 5001 and 5002.
# 5001 should have a readable gateway (part of the API)
# 5002 should have a readable gateway (using ipfs config Addresses.Gateway)
# but ideally we should only write the tests once. so maybe we need to
# define a function to test a gateway, and do so for each port.
# for now we check 5001 here as 5002 will be checked in gateway-writable.

test_expect_success "GET IPFS path succeeds" '
  echo "Hello Worlds!" > expected &&
  HASH=`ipfs add -q expected` &&
  wget "http://127.0.0.1:$port/ipfs/$HASH" -O actual
'

test_expect_success "GET IPFS path output looks good" '
  test_cmp expected actual &&
  rm actual
'

test_expect_success "GET IPFS directory path succeeds" '
  mkdir dir &&
  echo "12345" > dir/test &&
  HASH2=`ipfs add -r -q dir | tail -n 1` &&
  wget "http://127.0.0.1:$port/ipfs/$HASH2"
'

test_expect_success "GET IPFS directory file succeeds" '
  wget "http://127.0.0.1:$port/ipfs/$HASH2/test" -O actual
'

test_expect_success "GET IPFS directory file output looks good" '
  test_cmp dir/test actual
'

test_expect_failure "GET IPNS path succeeds" '
  ipfs name publish "$HASH" &&
  NAME=`ipfs config Identity.PeerID` &&
  wget "http://127.0.0.1:$port/ipns/$NAME" -O actual
'

test_expect_failure "GET IPNS path output looks good" '
  test_cmp expected actual
'

test_expect_success "GET invalid IPFS path errors" '
  test_must_fail wget http://127.0.0.1:$port/ipfs/12345
'

test_expect_success "GET invalid path errors" '
  test_must_fail wget http://127.0.0.1:$port/12345
'

test_expect_success "GET /webui returns code expected" '
  test_curl_resp_http_code "http://127.0.0.1:$apiport/webui" "HTTP/1.1 302 Found\s" "HTTP/1.1 301 Moved Permanently\s"
'

test_expect_success "GET /webui/ returns code expected" '
  test_curl_resp_http_code "http://127.0.0.1:$apiport/webui/" "HTTP/1.1 302 Found\s" "HTTP/1.1 301 Moved Permanently\s"
'

test_kill_ipfs_daemon

test_done
