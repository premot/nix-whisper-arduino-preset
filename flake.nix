{
  description = "Opt-in Whisper.cpp and Arduino CLI tool preset";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      perSystem = system:
        let
          pkgs = import nixpkgs { inherit system; };
          tools = with pkgs; [
            arduino-cli
            whisper-cpp
            ffmpeg
          ];
          preset = pkgs.symlinkJoin {
            name = "whisper-arduino-preset";
            paths = tools;
            meta.description = "Whisper.cpp, Arduino CLI, and FFmpeg";
          };
        in {
          packages = {
            whisper-arduino = preset;
            default = preset;
          };

          devShells = {
            whisper-arduino = pkgs.mkShell {
              packages = tools;
              shellHook = ''
                echo "Whisper + Arduino preset active"
                echo "Try: arduino-cli version; whisper-cli --help"
              '';
            };
            default = pkgs.mkShell { packages = tools; };
          };
        };
    in {
      packages = forAllSystems (system: (perSystem system).packages);
      devShells = forAllSystems (system: (perSystem system).devShells);
    };
}
