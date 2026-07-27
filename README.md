# Machine-local Whisper + Arduino/AVR tools

This separate flake keeps bulky, machine-specific tools out of reusable NixOS
and Home Manager configuration. It is consumed by the `prototype` profile in
[`premot/v2`](https://github.com/premot/v2), while that repository's reusable
disk profiles deliberately omit it. The preset contains `whisper-mic`,
`whisper-cli`, `arduino-cli`, `avr-gcc`, `avrdude`, GNU Make, and `picocom`.
`whisper-mic` records until a keypress, transcribes locally with the pinned
multilingual base model, and copies the transcription to the Wayland clipboard.
It prefers a connected USB microphone; otherwise it uses PipeWire's configured
default microphone.

## Keep the commands available on this machine

Install the preset in the user's imperative Nix profile:

```bash
nix profile add path:$PWD
```

The commands then remain on `PATH` and survive rebuilds without becoming part
of any system generation or being installed when the main configuration is
reused. Remove everything with:

```bash
nix profile remove nix-whisper-arduino-preset
```

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

## Transcribe from the microphone

With the preset installed or its development shell open, run:

```bash
whisper-mic
```

It reports whether it found a USB microphone, starts recording, and stops on
any keypress in the terminal. The resulting transcription is printed and copied
to the clipboard. The command uses the local `whisper-cli` model only; it does
not send audio or text to a remote service.

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
tldr: run with ./scripts/preset shell
