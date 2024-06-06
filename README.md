# tor env-configurable docker
Docker `tor` daemon on Alpine Linux with auto config using env vars

Allows to specify tor hidden services providing key in env (or generating it automatically)

Available on `hub.docker.com` as: `darktool/tor`

Operation modes:
1. __proxy__ - socks5 proxy to .onion domains (default)
2. __hidden__ - .onion hidden service
3. __relay__ - bridge mode

Take appropriate `docker-compose.yml` and run:
```bash
docker compose up -d
```

# configuration examples
## proxy: tor socks5 proxy on `9050/tcp`
```yml
services:
  tor:
    image: darktool/tor
    restart: always
    ports:
      - 9050:9050
    tmpfs:
      - /var/lib/tor:size=128M,uid=100,gid=65533,mode=1700
```

## hidden: tor hidden service
```yml
services:
  nginx:
    image: nginx
    restart: always
  tor:
    image: darktool/tor
    restart: always
    depends_on:
      - nginx
    tmpfs:
      - /var/lib/tor:size=128M,uid=100,gid=65533,mode=1700
    environment:
      HIDDEN_KEY: fnitj2e3fagt5zdjndhuszo7wxlhoedl7kpuore6ateaxohj6gmclead.onion:qBi4NG6Jnopdn1aSG8OnodSBYD1ChHZ0zP8M+sy7iG1Si8dhNfg6EfxthJkMkfj5XZeNLEs0HNSecZdNR+OP0g==
      HIDDEN: 80:nginx:80
```
Run `curl http://fnitj2e3fagt5zdjndhuszo7wxlhoedl7kpuore6ateaxohj6gmclead.onion` on client to connect to `nginx` service

## relay: tor bridge on 9999/tcp
```yml
services:
  tor:
    image: tool/tor
    restart: always
    environment:
      RELAY: 1
    ports:
      - 9999:9999
    volumes:
      - tor:/var/lib/tor:rw
volumes:
  tor: {}
```
Logs out bridge parameters (suitable for `BRIDGES` env)

## key generation
`mkp224o` utility is used for key generation ([https://github.com/cathugger/mkp224o.git]), appropriate `keygen` bash script usage: `keygen [mask]`

## env
Main:
- `RELAY`: enable relay mode (any non-zero value), undefined by default, incompatible with `HIDDEN` or `BRIDGES`
- `HIDDEN`: list of hidden ports: `80:nginx:80 22:git:22`
- `HIDDEN_KEY`: .onion domain + private key in hex: `$DOMAIN:$KEY`, auto generated if empty (logged)
- `BRIDGES`: bridge list: `Bridge obfs4 1.2.3.4:9999 ... cert=... iat-mode=0`, multi-line supported

Secondary:
- `LOGLEVEL`: debug, info, notice, warn, err/error; default is `notice`
- `ENTRYNODES` and `EXITNODES`: entry/exit nodes filter, default `{kz},{lk},{lt},{lv},{ee},{ro},{rs},{sa},{si},{th},{tj},{tr},{uz},{vn},{cn},{ly},{ma},{md},{mk},{mn},{mt},{om},{ph},{pl},{qa},{ae},{kw},{am},{az},{bg},{bh},{bn},{by},{cy},{dz},{eg},{ge},{hk},{hr},{hu},{id},{in},{jo},{kg}`
- `CONTROL_PORT`: control service port, default `9051`
- `CONTROL_PASSWORD`: control service password, default is empty
- `CONF`: any `torrc` configuration options: multi-line, for example: `ConnLimit 256` (user is fully responsible for config conflicts)

## exposes
- `9050/tcp`: tor socks proxy
- `9051/tcp`: control service
- `9053/tcp` and `9053/udp`: tor dns

## persistance
Data can be persisted and config manual edited by mounting the `/var/lib/tor`.

## hashed password
```bash
$ tor --quiet --hash-password password
16:3ED9D6613C3D2F7F60C682884D9E168B30F7E247B2F29B9C4291A698ED
```
