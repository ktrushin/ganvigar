ARG base=oraclelinux:8
FROM $base

ENV TERM=linux

ARG username
ARG groupname
ARG uid
ARG gid
ARG locale=en_US.UTF-8

RUN dnf install -y sudo
RUN groupadd --gid $gid $groupname && \
    useradd --uid $uid --gid $gid --groups users --comment '' --create-home $username && \
    echo "$username ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$username && chmod 640 /etc/shadow

ENV LANG=$locale LC_ALL=$locale

RUN dnf install -y man-db man-pages bash-completion coreutils tree jq gnupg ca-certificates curl \
    wget git vim python3 python3-pip
