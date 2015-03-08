#!/bin/sh
#
# Copyright (c) 2014 Juan Batiz-Benet
# MIT Licensed; see the LICENSE file in this repository.
#

test_description="Test daemon command"

. lib/test-lib.sh

# this needs to be in a different test than "ipfs daemon --init" below
test_expect_success "setup IPFS_PATH" '
  IPFS_PATH="$(pwd)/.go-ipfs"
'

# NOTE: this should remove bootstrap peers (needs a flag)
test_expect_success "ipfs daemon --init launches" '
  ipfs daemon --init >actual_daemon 2>daemon_err &
'

# this is like "'ipfs daemon' is ready" in test_launch_ipfs_daemon(), see test-lib.sh
test_expect_success "initialization ended" '
  IPFS_PID=$! &&
  pollEndpoint -ep=/version -v -tout=1s -tries=60 2>poll_apierr > poll_apiout ||
  test_fsh cat actual_daemon || test_fsh cat daemon_err || test_fsh cat poll_apierr || test_fsh cat poll_apiout
'

# this is lifted straight from t0020-init.sh
test_expect_success "ipfs peer id looks good" '
  PEERID=$(ipfs config Identity.PeerID) &&
  echo $PEERID | tr -dC "[:alnum:]" | wc -c | tr -d " " >actual &&
  echo "46" >expected &&
  test_cmp_repeat_10_sec expected actual
'

# this is like t0020-init.sh "ipfs init output looks good"
test_expect_success "ipfs daemon output looks good" '
  STARTFILE="ipfs cat /ipfs/$HASH_WELCOME_DOCS/readme" &&
  echo "Initializing daemon..." >expected &&
  echo "initializing ipfs node at $IPFS_PATH" >>expected &&
  echo "generating 4096-bit RSA keypair...done" >>expected &&
  echo "peer identity: $PEERID" >>expected &&
  echo "to get started, enter:" >>expected &&
  printf "\\n\\t$STARTFILE\\n\\n" >>expected &&
  echo "API server listening on /ip4/127.0.0.1/tcp/5001" >>expected &&
  echo "Gateway (readonly) server listening on /ip4/127.0.0.1/tcp/8080" >>expected &&
  test_cmp_repeat_10_sec expected actual_daemon
'

test_expect_success ".go-ipfs/ has been created" '
  test -d ".go-ipfs" &&
  test -f ".go-ipfs/config" &&
  test -d ".go-ipfs/datastore" ||
  test_fsh ls .go-ipfs
'

test_expect_success "daemon is still running" '
  kill -0 $IPFS_PID
'

test_expect_success "'ipfs daemon' can be killed" '
  test_kill_repeat_10_sec $IPFS_PID
'

test_done
