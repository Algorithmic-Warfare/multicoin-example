FROM rust:1.79 as builder
RUN apt-get update && apt-get install -y clang cmake pkg-config libssl-dev git jq && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 https://github.com/MystenLabs/sui.git /sui-src
WORKDIR /sui-src
RUN cargo build --bin sui --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates jq bash && rm -rf /var/lib/apt/lists/*
COPY --from=builder /sui-src/target/release/sui /usr/local/bin/sui
WORKDIR /app
COPY . /app
EXPOSE 9000 9184 9123
ENTRYPOINT ["bash", "-c", "sui start --with-faucet"]