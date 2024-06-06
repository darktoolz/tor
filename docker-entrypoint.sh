#!/bin/sh

NODES="{kz},{lk},{lt},{lv},{ee},{ro},{rs},{sa},{si},{th},{tj},{tr},{uz},{vn},{cn},{ly},{ma},{md},{mk},{mn},{mt},{om},{ph},{pl},{qa},{ae},{kw},{am},{az},{bg},{bh},{bn},{by},{cy},{dz},{eg},{ge},{hk},{hr},{hu},{id},{in},{jo},{kg}"
export ENTRYNODES="${ENTRYNODES:=$NODES}"
export EXITNODES="${EXITNODES:=$NODES}"
export CONTROL_PORT="${CONTROL_PORT:=9051}"
export CONTROL_PASSWORD="${CONTROL_PASSWORD:=}"
export CONTROL_PASSWORD_HASH="${CONTROL_PASSWORD_HASH:=}"

if [ "x$LOGLEVEL" = "xerror" ]; then
  LOGLEVEL=err
fi
export LOGLEVEL="${LOGLEVEL:=notice}"

export TOR_USER=${TOR_USER:=tor}
export TOR_GROUP=${TOR_GROUP:=nogroup}
export TOR_UID=${TOR_UID:=100}
export TOR_GID=${TOR_GID:=65533}

# for internal usage
export RC=${RC:=/etc/tor/torrc}
export TOR=${TOR:=/var/lib/tor}
export istest=

field() {
d="$2"
n="$1"
cut -d "${d:=:}" -f "${n:=1}"
}
md5() { md5sum | field 1 " "; }
die() { echo "Fatal: $1"; exit 1; }
isuser() { test `whoami` = "$1"; }
istest() { test -n "$istest"; }
show() {
  for x in 1 2 3 4 5 6 7 8 9 10; do
    if [ -n "$RELAY" ]; then
      if [ -f $TOR/fingerprint ] && [ -f $TOR/pt_state/obfs4_bridgeline.txt ]; then
				myip="`curl -qs ident.me`"
				echo "Bridge obfs4 $myip:9999" $(grep -oE '(\w+)$' $TOR/fingerprint | tr -d "\n") $(grep cert $TOR/pt_state/obfs4_bridgeline.txt | tr -d "\n" | grep -oE '( cert=.*)$') # '
        break
      fi
    else
      if [ -n "$HIDDEN" ] && [ -f $TOR/hidden/hostname ] && [ -f $TOR/hidden/hs_ed25519_secret_key ] && [ -f $TOR/hidden/hs_ed25519_public_key ]; then
        echo "HIDDEN_KEY=`cat $TOR/hidden/hostname`:`base64 -w0 $TOR/hidden/hs_ed25519_secret_key`"
        echo "HIDDEN=$HIDDEN"
        break
      fi
    fi
    sleep 1
  done
}

tor_password() {
	istest && echo "\"$1\"" || tor --quiet --hash-password "$1"
}
tor_private_path() {
  mkdir -p "$1"
  isuser root && chown -R $TOR_UID:$TOR_GID "$1" && chmod 'u+rwX,og-rwx' "$1"
}

rc_config() {
tor_private_path $TOR
cat <<EOF
ClientUseIPv6 0
ContactInfo yourname@example.com
DataDirectory $TOR
DirReqStatistics 0
ExtORPort auto
ExtraInfoStatistics 0
Log $LOGLEVEL stderr
PublishServerDescriptor 0
User $TOR_USER
EOF
[ -n "$CONF" ] && echo "$CONF"
}
rc_proxy() {
cat <<EOF
SocksPort 0.0.0.0:9050
DNSPort 0.0.0.0:9053
SocksPolicy accept 127.0.0.0/8
SocksPolicy accept 10.0.0.0/8
SocksPolicy accept 192.168.0.0/16
SocksPolicy accept 172.16.0.0/12
SocksPolicy reject *
EOF
}
rc_hidden() {
hidden="$TOR/hidden"
tor_private_path "$hidden"
echo "HiddenServiceDir $hidden"
if [ -n "$HIDDEN_KEY" ]; then
	echo "$HIDDEN_KEY" | field 1 > "$hidden/hostname"
	echo "$HIDDEN_KEY" | field 2 | base64 -d > "$hidden/hs_ed25519_secret_key"
fi
for i in $HIDDEN; do
  echo HiddenServicePort "$i" | sed 's/:/ /'
done
}
rc_relay() {
cat <<EOF
BridgeRelay 1
ORPort 0.0.0.0:29351
SOCKSPort 0
ExitPolicy reject *:*
ServerTransportListenAddr obfs4 0.0.0.0:9999
ServerTransportPlugin obfs4 exec /usr/bin/lyrebird -enableLogging -logLevel INFO
EOF
}
rc_bridge() {
cat <<EOF
UseBridges 1
ClientTransportPlugin obfs4 exec /usr/bin/lyrebird
EOF
[ -n "$BRIDGES" ] && echo "$BRIDGES"
}
rc_entrynodes() {
echo "EntryNodes ${ENTRYNODES} StrictNodes 1"
}
rc_exitnodes() {
echo "ExitNodes ${EXITNODES} StrictNodes 1"
}
rc_control() {
	echo "ControlPort $CONTROL_PORT"
	if test -z "$CONTROL_PASSWORD_HASH"; then
		CONTROL_PASSWORD_HASH="`tor_password "${CONTROL_PASSWORD}"`"
	fi
	echo "HashedControlPassword $CONTROL_PASSWORD_HASH"
}

create_config() {
  if [ -n "$RELAY" ]; then
    [ -z "$HIDDEN$BRIDGES" ] || die "conflict: RELAY and HIDDEN/BRIDGES both defined"
		rc_config
		rc_relay
    return
  fi
  rc_config
  rc_control
  rc_proxy
  [ -n "$HIDDEN" ] && rc_hidden
  if [ -n "$BRIDGES" ]; then
    rc_bridge
  else
    rc_entrynodes
  fi
  rc_exitnodes
}
start_default() {
	create_config > $RC
  if tor --quiet --verify-config -f $RC; then
    [ -n "$RELAY$HIDDEN" ] && "$0" show &
    exec tor
  else
    tor --verify-config -f $RC
    cat $RC
    sleep 60
    exit 1
  fi
}
run_test() {
	export istest=1
	t="$1"
	[ -n "$t" ] || die "test name empty"
	[ -f "./testdata/$t.env" ] || die "require test name"
	export TOR=testdata/tor/$t
	export RC=testdata/$t.rc
	. "./testdata/$t.env"
	if [ -f "$RC" ]; then
		test "`create_config | md5`" = "`cat $RC | md5`"
	else
		create_config
	fi
}
case "$1" in
  show|info)
    show;;
  sh|bash)
    exec "$1";;
	test)
		run_test "$2";;
  "")
    start_default;;
  *)
    exec "$@";;
esac
