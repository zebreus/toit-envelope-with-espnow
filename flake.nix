{
  description = "Strassenbahnanzeige";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?rev=60a783e00517fce85c42c8c53fe0ed05ded5b2a4";
    nixpkgs-esp-dev = {
      url = "github:mirrexagon/nixpkgs-esp-dev?rev=08e4dff0460dad6c25edb4c1c9c53928f2449542";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nixpkgs-esp-dev,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;

          overlays = [
            (final: prev: {
              esp-idf-full =
                # nixpkgs-esp-dev.packages.${system}.esp-idf-full;
                let
                  rev = "91ccc17ec413faf0ac232fcd796524337f04384c";
                  sha256 = "sha256-lJbp0Z1zrVrJ9ObUlEp2J51cIviAB8C4mHT5FRbYqWI=";
                in
                (
                  (nixpkgs-esp-dev.packages.${system}.esp-idf-full.override {
                    rev = rev;
                    sha256 = sha256;

                  }).overrideAttrs
                  (
                    a: b: {
                      src = final.fetchFromGitHub {
                        owner = "toitware";
                        repo = "esp-idf";
                        rev = rev;
                        sha256 = sha256;
                        fetchSubmodules = true;
                      };
                    }
                  )
                );
            })
          ];
        };
      in
      {
        name = "rudelblinken-envelope";

        packages.default = pkgs.writeShellApplication {
          name = "build-firmware";
          runtimeInputs = [
            pkgs.esp-idf-full
            (pkgs.clang-tools.override { })
            pkgs.glibc_multi.dev
            pkgs.zlib
            pkgs.go
            pkgs.git
          ];
          text = ''
            set -x
            set -e
            ORIGINAL_DIR="$(pwd)"
            test -n "$HOME" || exit 1
            mkdir -p "$HOME"/.cache/build-firmware
            REPO_DIR=$HOME/.cache/build-firmware/rudelblinken-envelope
            if ! test -d "$REPO_DIR" ; then
              git clone --recursive https://github.com/zebreus/toit-envelope-with-espnow "$REPO_DIR"
            fi
            cd "$REPO_DIR"
            git stash
            git pull -f

            cd toit
            git tag -f v2.0.0-alpha.160
            cd ..

            make init
            make
            cp build/esp32c3/firmware.envelope "$ORIGINAL_DIR/esp32c3-firmware.envelope"
            echo Use "'jag flash esp32c3-firmware.envelope --chip esp32c3 --wifi-ssid rudelctrl --wifi-password 22po7gl334ai --name INSERT_UNIQUE_NAME'"
          '';
        };

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.esp-idf-full
            (pkgs.clang-tools.override { })
            pkgs.glibc_multi.dev
            pkgs.zlib
            pkgs.go
            pkgs.steam-run
          ];

          shellHook = ''
            function wrapProgram() {
              local directory="$(dirname $1)"
              local file="$(basename $1)"
              mv $directory/$file $directory/.unwrapped_$file
              cat <<EOF > $directory/$file
            #!/usr/bin/env bash
            steam-run $directory/.unwrapped_$file "\$@"
            EOF
            chmod a+x $directory/$file
            }

            # Add a directory for binaries that will be linked into path
            mkdir -p ~/.cache/hackyJaguarFlake/bin
            export PATH=~/.cache/hackyJaguarFlake/bin:$PATH

            # Install the latest jag via go into the user home
            go install github.com/toitlang/jaguar/cmd/jag@latest 

            # Create a steam-run wrapper in our bin directory
            cat <<EOF > ~/.cache/hackyJaguarFlake/bin/jag
            #!/usr/bin/env bash
            steam-run $HOME/go/bin/jag "\$@"
            EOF
            chmod a+x ~/.cache/hackyJaguarFlake/bin/jag

            # Download toit and jaguar tools
            # And wrap them in steam-run
            if ! jag setup --check ; then
              jag setup
              find $HOME/.cache/jaguar/sdk -type f -executable | while read line ; do
                wrapProgram $line
              done
            fi

            # Link jaguar tools into temporary bin
            find $HOME/.cache/jaguar/sdk/bin $HOME/.cache/jaguar/sdk/tools -type f -executable | while read line ; do
              ln -sf $line ~/.cache/hackyJaguarFlake/bin/$(basename $line)
            done

            # Open udp port 1990 for finding jaguar devices
            if which nft ; then
              sudo nft add rule inet nixos-fw input-allow udp dport 1990 accept
            else
              echo Make sure that UDP port 1990 is open, otherwise scanning for esp devices wont work
            fi
          '';
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
