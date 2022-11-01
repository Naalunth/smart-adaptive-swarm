# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.245.2/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): ubuntu-22.04, ubuntu-20.04, ubuntu-18.04
ARG VARIANT="jammy"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
     && apt-get -y install --no-install-recommends lua5.4 liblua5.4-0 liblua5.4-dev build-essential cmake tup

RUN wget https://luarocks.org/releases/luarocks-3.9.1.tar.gz \
    && tar zxpf luarocks-3.9.1.tar.gz \
    && cd luarocks-3.9.1 \
    && ./configure && make && sudo make install

RUN luarocks install yuescript