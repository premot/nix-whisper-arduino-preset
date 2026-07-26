{
  description = "Machine-local microphone transcription and AVR/Arduino tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      perSystem = system:
        let
          pkgs = import nixpkgs { inherit system; };

          whisperModel = pkgs.fetchurl {
            url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
            hash = "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4=";
          };

          whisperMic = pkgs.writeShellApplication {
            name = "whisper-mic";
            runtimeInputs = [ pkgs.coreutils pkgs.pipewire pkgs.whisper-cpp ];
            text = ''
              if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && ! [[ "$1" =~ ^[1-9][0-9]*$ ]]; }; then
                echo "Usage: whisper-mic [recording-seconds]" >&2
                exit 2
              fi

              seconds="''${1:-10}"
              audio="$(mktemp --suffix=.wav)"
              trap 'rm -f "$audio"' EXIT

              echo "Recording from the default microphone for $seconds second(s)..." >&2
              pw-record --media-category Capture --media-role Communication \
                --rate 16000 --channels 1 --format s16 "$audio" &
              recorder=$!
              sleep "$seconds"
              kill -INT "$recorder" 2>/dev/null || true
              wait "$recorder" || true

              if [ ! -s "$audio" ]; then
                echo "No audio was captured. Select or unmute a microphone in GNOME Sound settings." >&2
                exit 1
              fi

              exec whisper-cli --model ${whisperModel} --language auto --no-timestamps "$audio"
            '';
          };

          tools = with pkgs; [
            whisperMic
            whisper-cpp
            arduino-cli
            avrdude
            gnumake
            picocom
            pkgsCross.avr.buildPackages.gcc
          ];

          preset = pkgs.symlinkJoin {
            name = "whisper-arduino-preset";
            paths = tools;
            meta.description = "Microphone transcription and AVR/Arduino tools";
          };
        in {
          packages = {
            whisper-arduino = preset;
            default = preset;
          };

          devShells = {
            whisper-arduino = pkgs.mkShell { packages = tools; };
            default = pkgs.mkShell { packages = tools; };
          };
        };
    in {
      packages = forAllSystems (system: (perSystem system).packages);
      devShells = forAllSystems (system: (perSystem system).devShells);
    };
}
