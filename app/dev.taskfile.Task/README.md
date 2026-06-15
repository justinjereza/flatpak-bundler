Task
====

It is assumed that making `podman.socket` available on the host system means
that the user also wants to make it available inside the application hence
permission to access it is given by default.

No other filesystem access is granted by default. The following are examples
for making files accessible to Task.

```sh
$ flatpak override --user --filesystem=home/sandbox:ro
$ flatpak override --user --filesystem=home/taskfiles:rw

# Gives write access to your entire home directory.
# Not recommended if you are limiting the attack surface.
$ flatpak override --user --filesystem=home:rw
```

Assuming you have created `$HOME/taskfiles/Taskfile.yaml` with a default task,
you can execute `flatpak run dev.taskfile.Task` from within `$HOME/taskfiles/`.
