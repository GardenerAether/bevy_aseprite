{
  description = "Bevy Aseprite Parser and Loader";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      defaultSystems = function: nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ] (system: function {inherit system; pkgs = import nixpkgs {inherit system; }; });

      libs = pkgs: with pkgs; [
        alsa-lib
        libGL
        vulkan-tools vulkan-headers vulkan-loader vulkan-validation-layers
        udev
        clang mold
        libxkbcommon wayland
      ];
    in {
      packages = defaultSystems ({ system, pkgs }: rec {
        bevy-test = pkgs.rustPlatform.buildRustPackage {
          pname = "bevy-test";
          version = "0.1";
          cargoLock.lockFile = ./Cargo.lock;
          buildInputs = (with pkgs; [gpp pkg-config]) ++ libs pkgs;
          src = pkgs.lib.cleanSource ./.;
        };

        default = bevy-test;
      });

      devShells = defaultSystems ({ system, pkgs }: rec {
        bevy-test = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.bevy-test ];
          buildInputs = with pkgs; [ rust-analyzer rustfmt clippy ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (libs pkgs);
        };

        default = bevy-test;
      });
    };
}

