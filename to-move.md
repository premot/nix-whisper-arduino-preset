Yes—**for ordinary command-line packages, it is very easy**.

Current arrangement:

- **`v2-main`** owns the reproducible NixOS/Home Manager core.
- **`nix-whisper-arduino-preset`** owns this machine’s optional/bulky tools.
- In [`v2-main/hosts/prototype/local-tools.nix`](/home/prototype/v2-main/hosts/prototype/local-tools.nix), the `prototype` configuration installs the preset as one system package.
- The reusable `disk-*` configurations do **not** include it.

So to move, for example, `picocom`, `neovim`, or `cargo` out of main:

1. Remove it from [`v2-main/modules/nixos/programs/packages.nix`](/home/prototype/v2-main/modules/nixos/programs/packages.nix).
2. Add it to the preset’s `tools` list in [`nix-whisper-arduino-preset/flake.nix`](/home/prototype/nix-whisper-arduino-preset/flake.nix):

```nix
tools = with pkgs; [
  whisperMic
  whisper-cpp
  arduino-cli
  avrdude
  gnumake
  picocom
  pkgsCross.avr.buildPackages.gcc

  neovim
  cargo
  rustc
];
```

Whether it remains globally available depends on how you use the preset:

- `prototype` rebuild: it stays globally on `PATH`, because `local-tools.nix` installs the preset.
- `nix profile add path:...`: it is available only in your user Nix profile.
- `nix develop ...`: it is available only in the development shell.
- `disk-main`, `disk-p4`, or `disk-ata`: it is omitted entirely, preserving their reusable/minimal nature.

## Important caveat: the current main flake uses the published preset

[`v2-main/flake.nix`](/home/prototype/v2-main/flake.nix) currently points to:

```nix
url = "github:premot/nix-whisper-arduino-preset/v1.0.0";
```

Therefore, changing the local `/home/prototype/nix-whisper-arduino-preset` checkout **does not automatically change `v2-main`**. The normal flow is:

1. Edit the preset.
2. Run `nix flake check` there.
3. Commit/push it and publish a new tag, e.g. `v1.1.0`.
4. Change the tag in `v2-main/flake.nix`.
5. Update `v2-main/flake.lock`, validate, and rebuild.

For local experimentation, you can temporarily make the `whisper-arduino` input a local path:

```nix
whisper-arduino.url = "path:/home/prototype/nix-whisper-arduino-preset";
```

Then `v2-main` immediately evaluates the local preset. That is convenient while developing, but should usually be changed back to a versioned GitHub tag before committing, so the configuration stays reproducible elsewhere.

## What is appropriate to move?

Good candidates:

- personal/optional CLI tools: `btop`, `htop`, `tree`, `tldr`, `emacs`, `neovim`
- language toolchains: `cargo`, `rustc`, `clang`, `jdk25`
- side-project utilities: Arduino, AVR, serial, etc.
- large occasional GUI/dev tools: perhaps `chromium`, `virt-manager`, `distrobox`

Usually keep in `v2-main`:

- boot, filesystem, networking, users, audio, desktop configuration
- packages required to administer or recover the base system
- anything whose NixOS module/configuration is needed, rather than merely its executable—e.g. `libvirt` service configuration and `programs.nix-ld.enable`

In short: **moving plain package entries is a small list edit; moving services or system behavior is not.**
