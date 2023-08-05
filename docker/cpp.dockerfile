ARG base
FROM $base

ARG username
ARG groupname
ARG uid
ARG gid

RUN apt-get update && apt-get install --yes --no-install-recommends \
        binutils g++ g++-12 mold \
        clang clang-15 lld llvm \
        # libc++-dev \
        clang-format clang-tidy clang-tools \
        gdb lldb ltrace strace google-perftools valgrind libtree \
        autoconf automake m4 autotools-dev libtool \
        make ninja-build cmake cmake-data scons meson ccache pkg-config \
        doxygen graphviz \
        libboost-all-dev libjemalloc-dev libgoogle-perftools-dev
