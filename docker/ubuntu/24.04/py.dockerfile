ARG base=ubuntu:latest
FROM $base

ARG username
ARG groupname
ARG uid
ARG gid

ENV PYTHONDONTWRITEBYTECODE=1

RUN add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && apt-get install --yes --no-install-recommends \
    python3.9 python3.9-dev python3.9-venv \
    python3.10 python3.10-dev python3.10-venv \
    python3.11 python3.11-dev python3.11-venv \
    python3.12 python3.12-dev python3.12-venv \
    python3.13 python3.13-dev python3.13-venv \
    pipx
RUN PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/usr/local/bin \
    PIPX_MAN_DIR=/usr/local/share/man \
    pipx install poetry
