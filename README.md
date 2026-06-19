Flatpak Bundler
===============

This build system creates Flatpak bundles in `artifacts/`. Flathub doesn't
accept command line applications so this makes it easier to maintain them
yourself.

Each application must have their own directory under `app/`and each runtime
must have their own directory under `runtime/`. Extensions are classified as
runtimes by Flatpak. Any directory ending in `.disabled` will not be built.

`app/dev.taskfile.Task/` and `runtime/dev.taskfile.Task.tool.podman/` are
working examples. `runtime/org.freedesktop.Platform.tool.podman.disabled/`
illustrates how to prevent a directory from being built.

Extensions that use an application as a runtime require that the application is
installed before being built. See the [individual applications](#individual-applications)
section for information on how to install an application separately.

Requirements
------------

* GNU Make
* Flatpak

Usage
-----

Change to the directory that contains the `Makefile` before you execute any of
the following commands.

```sh
# Install the required Flatpak packages.
$ make requirements
# Equivalent to the following:
$ make org.freedesktop.Platform org.freedesktop.Sdk org.flatpak.Builder

# Delete the build directory of every application/runtime and the repo.
$ make clean

# Delete the cache and all artifacts.
$ make distclean

# Export all applications/runtimes to the repo using Flatpak.
$ make export

# Bundle all applications/runtimes using Flatpak.
$ make bundle

# Install all applications/runtimes using Flatpak.
$ make install

# Export all applications/runtimes to the repo using Flatpak Builder.
$ make builder-export

# Install all applications/runtimes using Flatpak Builder.
$ make builder-install

$ make [all]
# Equivalent to the following:
$ make requirements bundle

# Allow 4 concurrent builds.
$ make -j4
```

### Individual Applications

The same operations can be made for an individual application/runtime. If you
have created `app/org.example.App/org.example.App.yaml` for example, the
following make commands are available.

```sh
$ make app/org.example.App-clean

# These two phases are separated in case you want to tweak the build.
$ make app/org.example.App-build
$ make app/org.example.App-finish

$ make app/org.example.App-export
$ make app/org.example.App-install
$ make app/org.example.App-builder-export
$ make app/org.example.App-builder-install

# Make a bundle.
$ FLATPAK_REF_BRANCH=stable
$ make artifacts/org.example.App-$FLATPAK_REF_BRANCH.flatpak
```

### Variables

Packages are installed to the user installation by default. You can set the
`FLATPAK_USER` variable to something other than `true` if you would like to
install to the system installation instead.

```sh
$ make FLATPAK_USER=false app/org.example.App-install
```

You can get more verbose output from Flatpak Builder using the
`FLATPAK_BUILDER_VERBOSE` variable.

```sh
$ make FLATPAK_BUILDER_VERBOSE=true app/org.example.App-build
```

Other variables that can be set and their defaults are at the top of
the `Makefile`.

### Configuration Files

Variables may also be overridden by putting them in `config.mk`.

```Makefile
# Apps will be exported to this branch.
FLATPAK_REF_BRANCH = 1.0
```

The name of the configuration file may be overridden.

```sh
$ make MAKE_CONFIG_FILE=my-other-config.mk app/org.example.App-install
```

Design Considerations
---------------------

### Why GNU Make?

GNU Make is ubiquitous, allows control of concurrent builds, and the author is
already quite familiar with it. It is simpler than writing the build system
with a shell script and implementing job management.

### Why Flatpak?

The frequency of supply chain attacks like the one reported on June 11, 2026
for the Arch Linux User Repository (AUR) have been increasing. Thus, the author
decided that it is prudent to use containers to limit the attack surface
available to programs being executed. This does not replace other security
mechanisms like SELinux.

The initial idea was to use Podman to run Task but that means writing yet
another shell script to handle the options to make resources available to the
container. Flatpak seems more ideal with the ability to retain information on
what resource access has been granted through overrides. This simplifies the
execution of the program to just the addition of its options instead of needing
to specify options for launching a container as well.

### Why is Task the example?

The author's shell scripts for building container images were taking too much
time to execute and Task looked like the solution for running tasks
concurrently. Furthermore, there is an opportunity to streamline multiple
scripts into a single Taskfile. Using Task means not having to develop a
similar piece of software. If he had to write one though, it'd most likely be
in Rust.

After installing Task, you can use it to run this system to update itself.

---

Copyright © 2026 Justin Jereza
