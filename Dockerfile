FROM ocaml/opam:ubuntu-22.04-ocaml-4.14 as app

WORKDIR /app

RUN sudo apt install -y pkg-config libev-dev libssl-dev

COPY grpc_proxy_sidecar.opam grpc_proxy_sidecar.opam

RUN opam install . --deps-only

COPY . .

RUN opam install .

RUN eval $(opam config env) && mv $(which grpc_proxy_sidecar) /app/grpc_proxy_sidecar
 
FROM ubuntu:jammy-20220301

RUN apt update
RUN apt install -y wget unzip libssl-dev libev-dev
RUN wget https://github.com/bradleyjkemp/grpc-tools/releases/download/v0.2.6/grpc-tools_0.2.6_Linux_amd64.zip
RUN mkdir grpc-tools
RUN unzip grpc-tools_0.2.6_Linux_amd64.zip -d grpc-tools
RUN mv grpc-tools/grpc-* /usr/bin

COPY --from=app /app/grpc_proxy_sidecar .

ENV PORT 1234
ENV DESTINATION localhost:3030
ENV INSPECT_PORT 8080
ENV PROTO_ROOT_DIR /opt

RUN which grpc-dump

ENTRYPOINT ./grpc_proxy_sidecar --port $PORT --dst $DESTINATION --http-port $INSPECT_PORT --proto-roots $PROTO_ROOT_DIR
