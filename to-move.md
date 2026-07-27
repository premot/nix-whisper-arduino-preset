# What belongs in this preset?

`nix-whisper-arduino-preset` is now the `prototype` machine's general optional
software preset, despite its historical repository name. The reusable
[`premot/v2`](https://github.com/premot/v2) NixOS and Home Manager configuration
owns the core system; this flake owns ordinary programs that are personal,
optional, bulky, or only occasionally needed.

Add a plain package to the `tools` list in [`flake.nix`](./flake.nix). For
example:

```nix
tools = with pkgs; [
  # Existing tools ...
  neovim
  cargo
  rustc
];
```

The package is then available from `.#preset`, `nix develop .#preset`, and
`./scripts/preset shell`. The historical `whisper-arduino` package and shell
names remain compatibility aliases.

## Good candidates

- personal CLI programs, editors, and terminal utilities;
- language toolchains and project-specific development tools;
- hardware utilities such as Arduino, AVR, serial, and YubiKey tools;
- large or occasional GUI and developer applications.

## Keep these in the core configuration

- boot, filesystem, networking, user, audio, and desktop configuration;
- packages needed to administer or recover the base system;
- software that needs NixOS service or module configuration rather than only an
  executable, such as a libvirt service or `programs.nix-ld.enable`.

Moving a plain package is a list edit. Moving a service or system behavior is
not: retain its required NixOS configuration in the core repository.

## Publishing changes for the main configuration

The `v2` flake consumes a versioned GitHub release of this repository, not this
working tree. After changing the preset:

1. Run `nix flake check` here.
2. Commit, push, and publish a new tag.
3. Update the preset input revision and lock file in `v2`.
4. Validate and rebuild `v2`.

For local experimentation, point the `v2` input at
`path:/home/prototype/nix-whisper-arduino-preset`. Change it back to a versioned
GitHub revision before committing `v2`, so other machines remain reproducible.
