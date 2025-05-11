ARG base=ubuntu:latest
FROM $base

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=linux

ARG username
ARG groupname
ARG uid
ARG gid
ARG locale=en_US.UTF-8

# Don't drop man pages and other files from the packages being installed
RUN mv /etc/dpkg/dpkg.cfg.d/excludes /tmp/dpkg_excludes.bk
# Reinstall all the already installed packages in order to
# get the man pages back
RUN dpkg -l | grep ^ii | cut -d' ' -f3 | \
        xargs apt-get install --yes --no-install-recommends --reinstall

# Install apt-utils before anything else
# the `DEBCONF_NOWARNINGS` environment variable suppresses the
# `debconf: delaying package configuration, since apt-utils is not installed`
# warning
RUN apt-get update && \
    DEBCONF_NOWARNINGS="yes" apt-get install --yes --no-install-recommends \
        apt-utils

# The Ubuntu 24.04 base image has the pre-created `ubuntu` user with
# UID and GID equal to 1000. Often a host user has the same UID and GID, which
# creates collision during mapping the host user to the image.
# @see https://bugs.launchpad.net/cloud-images/+bug/2005129
RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu
# Create the user and allow him to execute `sudo` without password
RUN apt-get update && apt-get install --yes --no-install-recommends adduser && \
    addgroup --gid $gid $username && \
    adduser --uid $uid --gid $gid --home /home/$username \
        --disabled-password --gecos '' $username && \
    adduser $username sudo && \
    mkdir -p /etc/sudoers.d/ && \
    echo "$username ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$username

# Set the locale
RUN apt-get update && apt-get install --yes --no-install-recommends locales && \
    locale-gen $locale && update-locale LANG=$locale LC_CTYPE=$locale
ENV LANG=$locale LC_ALL=$locale

RUN apt-get update && \
    TZ=UTC apt-get install --yes --no-install-recommends tzdata

RUN apt-get update && apt-get install --yes --no-install-recommends \
        man-db manpages manpages-dev manpages-posix manpages-posix-dev \
        apt-file apt-transport-https software-properties-common \
        sudo lsb-release bash-completion coreutils kitty tree less htop \
        ack jq mawk curl wget git gnupg ca-certificates vim neovim \
        python3 python3-pip \
        # tools for building Debian packages
        build-essential debhelper devscripts fakeroot dput
