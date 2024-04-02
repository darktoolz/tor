# auth
```
# echo -e 'AUTHENTICATE "password"\r\nHSFETCH\r\nQUIT' | nc 127.0.0.1 9051
250 OK
512 Bad arguments to HSFETCH: Need at least 1 argument(s)
250 closing connection
```
# .onion list
```
# echo -e 'AUTHENTICATE "password"\r\ngetinfo onions/current\r\nQUIT' | nc 127.0.0.1 9051
250 OK
250-onions/current=
250 OK
250 closing connection
```
# .onion detached list
```
# echo -e 'AUTHENTICATE "password"\r\ngetinfo onions/detached\r\nQUIT' | nc 127.0.0.1 9051
250 OK
250-onions/detached=
250 OK
250 closing connection
```
# network
```
# echo -e 'AUTHENTICATE "password"\r\ngetinfo network-liveness\r\nQUIT' | nc 127.0.0.1 9051
250 OK
250-network-liveness=up
250 OK
250 closing connection
```
# circuits
```
# echo -e 'AUTHENTICATE "password"\r\ngetinfo status/circuit-established\r\nQUIT' | nc 127.0.0.1 9051
250 OK
250-status/circuit-established=1
250 OK
250 closing connection
```
