# syntax=docker/dockerfile:1

ARG base
FROM $base

ARG username
ARG groupname
ARG uid
ARG gid

ENV PYTHONDONTWRITEBYTECODE=1

# Install pyenv and all python versions
RUN apt-get update && apt-get install --yes --no-install-recommends \
        make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
        libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
        xz-utils tk-dev libffi-dev liblzma-dev python3-openssl
RUN mkdir -p /extra && chown -R $username:$groupname /extra

USER $username

ENV PYENV_ROOT=/extra/pyenv
RUN curl -sSL https://pyenv.run | bash
ENV PATH=$PYENV_ROOT/bin:$PATH
RUN <<EOT
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    pyenv install 3.8 3.9 3.10 3.11 3.12
EOT
USER root
