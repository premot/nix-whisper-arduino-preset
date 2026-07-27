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
            runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.pipewire pkgs.whisper-cpp pkgs.wl-clipboard ];
            text = ''
              if [ "$#" -ne 0 ]; then
                echo "Usage: whisper-mic" >&2
                exit 2
              fi

              if [ ! -r /dev/tty ]; then
                echo "whisper-mic must be run from an interactive terminal." >&2
                exit 1
              fi

              audio="$(mktemp --suffix=.wav)"
              recorder=""

              stop_recording() {
                if [ -n "$recorder" ]; then
                  kill -INT "$recorder" 2>/dev/null || true
                  wait "$recorder" 2>/dev/null || true
                  recorder=""
                fi
              }

              cleanup() {
                stop_recording
                rm -f "$audio"
              }
              trap cleanup EXIT
              trap 'exit 130' INT TERM

              # Prefer an Audio/Source belonging to a USB device. If none exists,
              # leave source selection to PipeWire's configured default.
              usb_source="$(pw-dump | jq -r '
                . as $objects
                | [ $objects[]
                    | select(.type == "PipeWire:Interface:Device")
                    | select((.info.props["device.bus"] // "") == "usb")
                    | .id | tostring
                  ] as $usb_devices
                | [ $objects[]
                    | select(.type == "PipeWire:Interface:Node")
                    | select(.info.props["media.class"] == "Audio/Source")
                    | {
                        id,
                        device_id: (.info.props["device.id"] // "" | tostring),
                        details: [
                          .info.props["node.name"],
                          .info.props["node.description"],
                          .info.props["device.description"]
                        ] | map(select(. != null)) | join(" ")
                      }
                    | select(
                        (.device_id as $id | $usb_devices | index($id))
                        or (.details | test("usb"; "i"))
                      )
                  ]
                | sort_by(.id)
                | first
                | .id // empty
              ')"

              record_args=(
                --media-category Capture
                --media-role Communication
                --rate 16000
                --channels 1
                --format s16
              )
              if [ -n "$usb_source" ]; then
                record_args+=(--target "$usb_source")
                echo "Recording from USB microphone (PipeWire node $usb_source). Press any key to stop." >&2
              else
                echo "No USB microphone found; recording from the PipeWire default microphone. Press any key to stop." >&2
              fi

              pw-record "''${record_args[@]}" "$audio" &
              recorder=$!
              sleep 0.2
              if ! kill -0 "$recorder" 2>/dev/null; then
                wait "$recorder" || true
                echo "Could not start recording." >&2
                exit 1
              fi

              read -r -s -n 1 < /dev/tty || true
              stop_recording

              if [ ! -s "$audio" ]; then
                echo "No audio was captured. Select or unmute a microphone in GNOME Sound settings." >&2
                exit 1
              fi

              transcript="$(whisper-cli --model ${whisperModel} --language auto --no-timestamps "$audio")"
              printf '%s' "$transcript" | wl-copy
              printf '%s\n' "$transcript"
              echo "Transcription copied to the clipboard." >&2
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
