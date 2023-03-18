ARG base
FROM ${base}

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=linux

ARG username
ARG uid
ARG gid
ARG locale=en_US.UTF-8

# Don't drop man pages and other files from the packages being installed
RUN mv /etc/dpkg/dpkg.cfg.d/excludes /tmp/dpkg_excludes.bk
# Reinstall all the already installed packages in order to
# get the man pages back
RUN dpkg -l | grep ^ii | cut -d' ' -f3 | \
        xargs apt-get install --yes --no-install-recommends --reinstall

# Create the user and allow him to execute `sudo` without password
RUN addgroup --gid $gid $username && \
    adduser --uid $uid --gid $gid --home /home/$username \
        --disabled-password --gecos '' $username && \
    adduser $username sudo && \
    mkdir -p /etc/sudoers.d/ && \
    echo "$username ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$username

# Install apt-utils before anything else
# the `DEBCONF_NOWARNINGS` environment variable suppresses the
# `debconf: delaying package configuration, since apt-utils is not installed`
# warning
RUN apt-get update && \
    DEBCONF_NOWARNINGS="yes" apt-get install --yes --no-install-recommends \
        apt-utils

# Set the locale
RUN apt-get update && apt-get install --yes --no-install-recommends locales && \
    locale-gen $locale && update-locale LANG=$locale LC_CTYPE=$locale
ENV LANG=$locale LC_ALL=$locale

RUN apt-get update && \
    TZ=UTC apt-get install --yes --no-install-recommends tzdata

RUN apt-get update && apt-get install --yes --no-install-recommends \
        man-db manpages manpages-dev manpages-posix manpages-posix-dev \
        apt-file apt-transport-https software-properties-common \
        sudo lsb-release bash-completion coreutils tree less htop \
        ack jq mawk curl wget git gnupg ca-certificates vim neovim \
        python3 python3-pip \
        # tools for building Debian packages
        build-essential debhelper devscripts fakeroot dput
