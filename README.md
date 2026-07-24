# Opt-in Whisper + Arduino Nix preset

This is a separate flake repository that demonstrates an optional tool preset.
It does **not** modify NixOS configuration, Home Manager, or another repository's
flake. The normal system closure does not refer to these packages.

The preset contains:

- `whisper-cpp` (including `whisper-cli`)
- `arduino-cli`
- `ffmpeg` (a useful audio conversion companion for Whisper workflows)

Nix resolves each package's complete runtime closure when the preset is used.

## Use it temporarily

Enter the opt-in shell:

```bash
./scripts/preset shell
# equivalently: nix develop path:$PWD#whisper-arduino
```

The tools are on `PATH` only inside that shell. Exit it to return to the normal
environment. This is the preferred workflow for occasional side-project work.

## Keep the downloaded closure across garbage collection

A one-off `nix develop` typically leaves downloaded store paths available until
garbage collection, but does not promise to retain them. To explicitly retain
the preset without adding it to NixOS, enable this repository-local GC root:

```bash
./scripts/preset enable
./scripts/preset status
```

`enable` builds/downloads `.#whisper-arduino` and creates the ignored symlink
`.nix-presets/whisper-arduino`. Nix treats that build output link as a GC root,
so its entire closure persists across reboot and normal garbage collection for
as long as the link exists.

It still does not make the commands global. Start a shell whenever needed:

```bash
./scripts/preset shell
```

To stop retaining it:

```bash
./scripts/preset disable
```

This only removes the local GC root; it does not immediately delete anything
from `/nix/store`. A later Nix garbage collection may reclaim unreferenced paths.

## Validate the flake

```bash
nix flake check path:$PWD
```

## Updating package versions

The `flake.lock` file pins the nixpkgs revision. Review and update it explicitly:

```bash
nix flake update --flake path:$PWD
nix flake check path:$PWD
```

Commit the updated lock file with the flake change. No update here affects the
NixOS system flake or its lock file.
