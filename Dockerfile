FROM elixir:1.3
ADD . /udp_proxy
WORKDIR /udp_proxy
RUN mix local.hex --force && mix deps.get
ENV UPSTREAM_HOST 8.8.8.8
ENV UPSTREAM_PORT 53
CMD mix run --no-halt
EXPOSE 21137/udp