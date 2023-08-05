# Ganvigar
The project aims to facilitate the creation of development environments, i.e.
the Docker containers featuring the toolchains for the selected programming
languages. It also leaves room for customization of a development environment
to the needs of a particular project.

## Descripton
An environment is based on the last Docker image of a created image chain. The
very first element of the chain is is Ubuntu 22.04 Docker image with common
utilities installed and the current user mapped in the image. That image also
includes tools for Debian packaging.

On top of that base image, one can add toolchains for the selected programming
languages. At the time of writing, C++ and Python are supported. Adding a
toolchain for each language is done by building a Docker image from the previous
element of the image chain.

Finally, one can create a customized environment by building the image with
a user-provided dockerfile. The dockerfile must derive the image from the
current last element of the chain.

## Usage, Configuration, Artifacts
A development environment can be created as follows:
```shell
$ git clone git@github.com:ktrushin/ganvigar.git
$ cd /path/to/top/of/the/project/being/developed
$ /path/to/ganvigar/devenv-launch /path/to/the/config/file
```
The `devenv-lauch` command creates all the required images and the container. It
then starts the container and executes `bash` there interactively so the user
"enters" the development environment. If any of the artifacts (images,
container) already exists, it is reused.

### Configuration
Ganvigar configuration file must contain a single JSON object whose fields are:
- `languages` -- an array of strings; each string must be the name of a
  programming language; at the time of writing, `C++` and `Python` are
  supported; order in which the languages are specified does not matter;
  `C++`'s toolchain is also suitable for plain `C`;
- `image` -- an object describing the custom image which is derived from the
  current last element of the image chain; if specified, the Docker container
  for the environment will be created from that image.
  - `name` -- the name of the custom image;
  - `contextdir` -- the context directory with which the image is built;
    optional; default is the current working directory;
- `container` -- an object describing the container for the environment;
  - `name` -- the name of the container
  - `workdir` -- working directory to switch to in the container; optional;
    default is the current working directory
  - `options` -- string with additional options for the
    `docker container create` command; optional; default is empty string.

If `image.name` is specified, then `devenv-launch` assumes the dockerfile for
the image is located at the `<config_path>.dockerfile` path, where
`<config_path>` is the argument of `devenv-launch`. The dockerfile _must_ start
with the following snippet (not counting empty lines and comments):
```
ARG base
FROM $base
```
For the `deven-lauch` to take into account a custom dockeringore file to be
applied ot `image.contextdir` directory, it should be placed at the
`<config_path>.dockerfile.dockerignore` path. If such a file does not exist,
then `<image.contextdir>/.dockerignore` is used if the latter exists.

Both `image.name` and `container.name` support the `__USER_NAME__` macro, which
is replaced with a current username by `devenv-launch`. Using `image.name`
requires specifying `image.dockerfile`  and vice versa. All fields except
`container.name` are optional.

Example:
```json
{
    "languages": ["Python", "C++"],
    "image": {
        "name": "__USER_NAME__/my-proj-dev",
    },
    "container": {"name": "__USER_NAME__-my-proj-dev"}
}
```

### Artifacts
Given username `jdoe` and the above configuration, `devenv-lauch` produces the
following chain of images:
```
jdoe/u22
jdoe/u22-cpp
jdoe/u22-cpp-py
jdoe/my-proj-dev
```
where `jdoe/u22` is the very first element of the chain. It is derived from the
stock `ubuntu:22.04` image by adding the user and common utilities. On top of
`jdoe/u22`, `jdoe/u22-cpp` is built by installing the C++ toolchain. The third
element of the chain is `jdoe/u22-cpp-py`, which has the Python toolchain in
addition to everything from `jdoe/u22-cpp`. Finaly, `jdoe/my-proj-dev` is built
from `jdoe/u22-cpp-py` with a user-provided dockerfile.

For each image in the produced chain, the tag is the abbreviated MD5 sum of the
respective image inputs, i.e. all the data it depends on including base image
name and tag, dockerfile, username, files copied to the image, etc.

The `jdoe-my-proj-dev` container is created from the `jdoe/my-proj-dev` image.
User's home directory is mapped into the container, working directory is changed
to that from where `devenv-lauch` was run and the user is put into the
environment under its username.

One thing to be noted in the image chain is the `jdoe` prefix for the image
names. Although image tags already depend on the username, having the username
in an image name can simplify managing the images on the machines used
collectively by several developers. The `devenv-lauch` utility adds a username
automatically for each "standard" (`<username>/u22`, `<username>/u22-cpp` and
`<username>/u22-cpp-py`) image it creates. Having the prefix for the custom
image relies on the `__USER_NAME__` macro. The custom image is intentionally not
automatically prefixed with a username because that would create the image with
a name different from that specified in the configuration, thus confusing the
user.

## Usage Scenarios
### Simple Ubuntu Machine
It is sometimes convenient to have something similar to a spare instance of a
lightweight "virtual machine" for potentially desastrous testing. However,
the official Docker image for Ubuntu may be insufficient due to the lack of many
useful software packages. If jeopardizing the host operating system is not
desired, one can use the following configuration :
```shell
$ cat dangerous_experiment.conf
{"container": {"name": "dangerous_experiment"}}
```
The environment won't have any development toolchains at all, just some widely
used utilities are included. Unlike manually installing the software packages to
the container created from a stock Ubuntu image, `devenv-lauch` is capable of
quickly producing the environments for a series of repeated experiments when the
existing container is no more operational.

### Customized Ubuntu Machine
If the environment from the previous misses some packages, they
can be installed by creating a custom image:
```shell
$ cat
cat dangerous_experiment.conf
{
    "image": {
        "name": "dangerous_experiment",
    }
    "container": {"name": "dangerous_experiment"}
}
$ cat dangerous_experiment.conf.dockerfile
ARG base
FROM ${base}

RUN apt-get update && apt-get install --yes --no-install-recommends \
        first-utility second-utility
```

### Standard Development Environment
Almost every developer occasionally needs to check how some feature of the
language or the standard library works in a particular corner case. Below is the
example of the configuration for an isolated environment where that can be
tested:
```shell
$ cat my-test.conf
{
  "languages": ["C++"],
  "container": {"name": "my-test"}
}
```
A similar environment for Python can be obtained by replacing `"C++"` with
`"Python"` in the configuration file.

### Environment for a Third-Party Project
It is often convenient to place the configuration, dockerfile and dockeringore
file for the project in the `gangivar` directory at the top of the project and
put it under the source code versioning system. In that case, project's
environment state is always in line with the state of the project itself.
However convenient, the method described above is not always possible. For
instance, when one wants to use `devenv-launch` for the project she is not
a maintainer of. In that case, she can make use of the `image.contextdir` and
`container.workdir` configuration options. Just put configuration, dockerfile
and dockerignore (if necessary) elsewhere on the file system and use the path
to the project's top dir in the configuration:
```shell
$ cat some/path/to/my-proj-dev.conf
{
    "languages": ["C++", "Python"],
    "image": {
        "name": "__USER_NAME__/my-proj-dev",
        "contextdir": "/path/to/my/proj/top/dir"
    },
    "container": {
        "name": "my-proj-dev",
        "workdir": "/path/to/my/proj/top/dir"
    }
}
```

### Separating compile-time and runtime dependencies for C/C++
Given an `X` program written in C or C++, one may create two envronments: for
development and testing respectively. The first one contains X's compile-time
dependencies, the second one has exclusively runtime dependencies. Compared to
the "everything in one environment" approach, having separate environments for
development and testing minimizes the risk of not recognizing a package as an
`X`'s runtime dependency. That sometimes happens when third party libraries are
used. A typical C/C++ library is distributed as a pair of packages:
`lib<name>-dev` and `lib<name><soversion>`. Technically, `lib<name>-dev` also
often exists but it is not important now. For the `X` to be compiled,
`lib<name>-dev` must be present on the compilation machine. The `lib<name>-dev`
package usually depends on `lib<name><soversion>` and the latter is
automatically installed as a prerequisite of `lib<name>-dev` without any efforts
from the developer or build engineer. The fact that `X` needs
`lib<name><soversion>` in order to be run is often overlooked but the separate
development and testing environments make it clear since the compile-time
dependencies are not installed in the test environment.

Configuration prototypes for developement and testing environmens are below.
Development environment:
```shell
$ cat ganvigar/dev.conf
{
    "languages": ["C++"],
    "image": {
        "name": "__USER_NAME__/x-dev",
    },
    "container": {"name": "__USER_NAME__-x-dev"}
}
$ cat ganvigar/dev.conf.dockerfile
ARG base
FROM ${base}

RUN apt-get update && apt-get install --yes --no-install-recommends \
        libfoo-dev libbar-dev
```
Testing environment:
```shell
$ cat ganvigar/test.conf
{
    "image": {
        "name": "__USER_NAME__/x-test",
    },
    "container": {"name": "__USER_NAME__-x-test"}
}
$ cat ganvigar/test.conf.dockerfile
ARG base
FROM ${base}

RUN apt-get update && apt-get install --yes --no-install-recommends \
        libfoo3 libbar1 libnorf2 \
        first-helper-tool-for-testing second-helping-tool-for-testing
```

## Final words
The project was conceived for the author's own needs but he would be pleased if
others also find it useful.
