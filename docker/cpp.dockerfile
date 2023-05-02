ARG base
FROM ${base}

RUN apt-get update && apt-get install --yes --no-install-recommends \
        binutils g++ g++-12 mold \
        clang clang-15 lld llvm \
        # libc++-dev \
        clang-format clang-tidy clang-tools \
        gdb lldb ltrace strace google-perftools valgrind \
        autoconf automake m4 autotools-dev libtool \
        make ninja-build cmake cmake-data scons meson ccache pkg-config \
        doxygen graphviz \
        libboost-all-dev libjemalloc-dev libgoogle-perftools-dev
ENV CCACHE_DIR=/ccache
# allow everyone to read, write and execute; set the sticky bit
RUN mkdir -p $CCACHE_DIR && chmod a+rwx+t $CCACHE_DIR
