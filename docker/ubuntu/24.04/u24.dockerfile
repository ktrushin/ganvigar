ARG base=ubuntu:24.04
FROM $base

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=linux

ARG username
ARG groupname
ARG uid
ARG gid
ARG locale=en_US.UTF-8

# Don't drop man pages and other files from the packages being installed.
RUN mv /etc/dpkg/dpkg.cfg.d/excludes /tmp/dpkg_excludes.bk && \
    # Reinstall all the already installed packages in order to get the man pages back.
    apt-get install -y --reinstall $(dpkg -l | grep ^ii | cut -d' ' -f3)

# Install apt-utils before anything else.
# The `DEBCONF_NOWARNINGS` environment variable suppresses the
# `debconf: delaying package configuration, since apt-utils is not installed`
# warning
RUN apt-get update && DEBCONF_NOWARNINGS="yes" apt-get install -y apt-utils

# Set the locale
RUN apt-get update && apt-get install -y locales && locale-gen $locale && \
    update-locale LANG=$locale LC_CTYPE=$locale
ENV LANG=$locale LANGUAGE=$locale LC_ALL=$locale

# Install the `sudo` command
RUN apt-get update && apt-get install -y sudo

# The Ubuntu 24.04 base image has the pre-created `ubuntu` user with
# UID and GID equal to 1000. Often a host user has the same UID and GID, which
# creates collision during mapping the host user to the image.
# @see https://bugs.launchpad.net/cloud-images/+bug/2005129
RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu && \
    # Create the user and allow them to execute `sudo` without password
    groupadd --gid $gid $groupname && \
    useradd --uid $uid --gid $gid --groups users,sudo --comment '' --create-home $username && \
    echo "$username ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$username

RUN apt-get update && TZ=UTC apt-get install -y tzdata && apt-get install -y \
    man-db manpages manpages-dev manpages-posix manpages-posix-dev apt-file apt-transport-https \
    software-properties-common lsb-release fish bash-completion coreutils kitty-terminfo tree less \
    htop ack jq mawk curl wget git gnupg ca-certificates vim neovim python3 python3-pip \
    # tools for building Debian packages
    build-essential debhelper devscripts fakeroot dput
