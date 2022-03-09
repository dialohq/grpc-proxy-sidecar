# grpc-proxy-sidecar

Debug grpc in-transport with ease.

At Dialo we've experienced hard to debug issues where we weren't sure whether it's the server or the client at fault. This proxy allows you to intercept gRPC traffic in a readable json form.

> Do not use on production ⛔️. This tool was only tested as debugging aid.

## Usage example

This will start the proxy on port `9090` and will forward all grpc requests to `localhost:9091` (it assumes there's the _de facto_ gRPC server running there).

```
docker run \
  --network host \
  --mount type=bind,source="$(pwd)",target=/opt/ \
  --env PORT=9090 --env DESTINATION=localhost:9091 \
  --env INSPECT_PORT=8080 --env PROTO_ROOT_DIR=/opt/ \
  ghcr.io/dialohq/grpc-proxy-sidecar:sha-7724d47 
```

By default the proxy doesn't log any activity but you can attach an observer at any point.

Example with `curl` in the example above:

```
curl localhost:8080/tail
```

The subsequent gRPC requests will be streamed as the response. Notice that for streaming, you will only see the output after the stream is closed.

### Details

The following env variables are required:

- `PORT` - gRPC messages are expected to arrive on this port (integer)
- `PORT` - the gRPC messages are expected to arrive on this port
- `INSPECT_PORT` - the HTTP server for tailing will be opened on this port (integer)
- `PROTO_ROOT_DIR` - The directory (inside the container) where the proto definitions can be found (string)

## Contributing

To build locally using esy

```
esy @./grpc_proxy_sidecar.opam install
```
