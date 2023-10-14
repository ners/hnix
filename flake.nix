{
  description = "A Haskell re-implementation of the Nix expression language";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix = {
      url = "nix/624e38aa43f304fbb78b4779172809add042b513";
      flake = false;
    };
  };

  outputs = {
    nix,
    nixpkgs,
    self,
  } @ inp: let

    l = builtins //nixpkgs.lib;
    supportedSystems = ["x86_64-linux" "aarch64-darwin"];

    forAllSystems = f: l.genAttrs supportedSystems
      (system: f system (nixpkgs.legacyPackages.${system}));

  in {

    defaultPackage = forAllSystems
      (system: pkgs: import ./default.nix {
        inherit pkgs;
        withHoogle = true;
        compiler = "ghc8107";
        packageRoot = pkgs.runCommand "hnix-src" {} ''
          cp -r ${./.} $out
          chmod -R +w $out
          cp -r ${nix} $out/data/nix
        '';
      });

    devShell = forAllSystems (system: pkgs:
      let
        hp = pkgs.haskellPackages.override {
          overrides = self: super: with pkgs.haskell.lib; {
            hnix = super.callCabal2nix "hnix" ./. {};
            hnix-store-core = super.hnix-store-core_0_6_1_0;
            hnix-store-remote = super.hnix-store-remote_0_6_0_0;
          };
        };
      in
      hp.shellFor {
        packages = ps: [ ps.hnix ];
        nativeBuildInputs = with pkgs; with hp; [
          entr
          cabal-install
          haskell-language-server
        ];
      }
    );
  };
}
