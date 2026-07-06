# Cross-Compilation Using Docker

The `make.vsh` script in this directory performs cross-compilation of the
`hello.v` program for multiple platforms. For each binary file, it also
creates a file containing its SHA256 checksum.

The host is assumed to be a Linux machine with an x86_64 (amd64) architecture.

## How It Works

The core idea is to create a build environment within a Docker container, build
the application inside that container, and save the resulting binaries to a
directory on the host machine. A separate environment is created for each target
platform.

The `Build` struct contains all the initial information required to build the
application.

### 1. Generating the Dockerfile

This step is executed once before the build begins. The contents of the
Dockerfile are generated dynamically based on data from the `targets` constant
in `make.vsh`.

The `build_dockerfile` function creates a Dockerfile with multiple
`FROM ... AS ...` expressions, where the alias following `AS` represents the
target name in the format `OS-ARCH`.

First, a base image is created using Debian 13 (Trixie), containing the
`build-essential` package and the V compiler.

Next, specific DEB packages required for cross-compilation are installed for
each target.

Of course, this entire step could be omitted by simply writing the Dockerfile
manually.

See `build_dockerfile` function in make.vsh.

### 2. Building the Container Image

The script triggers the Docker image build process based on the Dockerfile
generated in the previous step.

See `docker-image-${target}` task in script.

### 3. Running the Build Inside the Container

The script starts the container using the `docker run ...` command, mounting the
path to the working directory (specified in `Build`) and passing the application
build command.

The command to build the application is generated dynamically based on the data
stored in the `Build` object.

See `build-${target}` task in make.vsh.

### 4. Creating checksum file

make.vsh reads the produced binaries and calculetes the SHA256 checksums for it.

See `build-${target}` task in make.vsh.
