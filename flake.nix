{
  description = "Kokua Viewer dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        python3
        python3Packages.pip
        cmake
        git
      ];

      shellHook = ''
        export AUTOBUILD_VARIABLES_FILE="/Users/kentronkokuaviewer.org/Documents/BitbucketProjects/viewer-build-variables/variables"
        export AUTOBUILD_ADDRSIZE=64
        echo "✅ Entorno Kokua activo"
        echo "   AUTOBUILD_VARIABLES_FILE=$AUTOBUILD_VARIABLES_FILE"
      '';
    };
  };
}
