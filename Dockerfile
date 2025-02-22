# syntax=docker/dockerfile:1-labs
FROM golang:1.19 as op

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/optimism
ENV VERSION=v1.1.1
ENV CHECKSUM=c0f3dbce8729016103b8390f9ee81089cd858242df6a45a42c59555f1c9e9106
ADD --checksum=sha256:$CHECKSUM $REPO/archive/op-node/$VERSION.tar.gz ./

RUN tar -xvf ./$VERSION.tar.gz --strip-components=1 && \
    cd op-node && \
    make op-node

FROM golang:1.19 as geth

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/op-geth
ENV VERSION=v1.101200.1-rc.2
ENV CHECKSUM=acdd027c85cf2edaec198f888a543445821182eaef461bc9d1a32527bd186ee3
ADD --checksum=sha256:$CHECKSUM $REPO/archive/$VERSION.tar.gz ./

RUN tar -xvf ./$VERSION.tar.gz --strip-components=1 && \
    go run build/ci.go install -static ./cmd/geth

FROM golang:1.19

RUN apt-get update && \
    apt-get install -y jq curl && \
    rm -rf /var/lib/apt/lists

WORKDIR /app

COPY --from=op /app/op-node/bin/op-node ./
COPY --from=geth /app/build/bin/geth ./
COPY geth-entrypoint .
COPY op-node-entrypoint .
COPY goerli ./goerli
COPY mainnet ./mainnet
