ARG base
FROM $base

ARG username
ARG groupname
ARG uid
ARG gid

RUN apt-get update && apt-get install --yes --no-install-recommends \
        # @note: the `bfd` and the `gold` linkers are included in
        # the `binunitls` package
        binutils llvm libtree lld mold \
        g++ g++-12 clang clang-15 \
        # libc++-dev \
        clang-format clang-tidy clang-tools \
        gdb lldb ltrace strace google-perftools valgrind \
        autoconf automake m4 autotools-dev libtool \
        make ninja-build cmake cmake-data scons meson ccache pkg-config \
        doxygen graphviz \
        libboost-all-dev libjemalloc-dev libgoogle-perftools-dev
