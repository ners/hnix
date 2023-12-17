{
  description = "A Haskell re-implementation of the Nix expression language";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix = {
      url = "nix/624e38aa43f304fbb78b4779172809add042b513";
      flake = false;
    };
    hnix-store = {
      url = "github:haskell-nix/hnix-store";
      flake = false;
    };
    dependent-sum-template = {
      url = "github:obsidiansystems/dependent-sum-template";
      flake = false;
    };
  };

  outputs = inputs: let

    l = builtins // inputs.nixpkgs.lib;
    supportedSystems = ["x86_64-linux" "aarch64-darwin"];

    forAllSystems = f: l.genAttrs supportedSystems
      (system: f system (inputs.nixpkgs.legacyPackages.${system}));

  in {

    defaultPackage = forAllSystems
      (system: pkgs: import ./default.nix {
        inherit pkgs;
        withHoogle = true;
        compiler = "ghc947";
        packageRoot = pkgs.runCommand "hnix-src" {} ''
          cp -r ${./.} $out
          chmod -R +w $out
          cp -r ${inputs.nix} $out/data/nix
        '';
      });

    devShell = forAllSystems (system: pkgs:
      let
        hp = pkgs.haskellPackages.override {
          overrides = self: super: with pkgs.haskell.lib; {
            dependent-sum-template = super.callCabal2nix "dependent-sum-template" inputs.dependent-sum-template { };
            hnix = super.callCabal2nix "hnix" ./. { };
            hnix-store-core = super.callCabal2nix "hnix-store-core" "${inputs.hnix-store}/hnix-store-core" { };
            hnix-store-db = super.callCabal2nix "hnix-store-db" "${inputs.hnix-store}/hnix-store-db" { };
            hnix-store-json = super.callCabal2nix "hnix-store-json" "${inputs.hnix-store}/hnix-store-json" { };
            hnix-store-nar = super.callCabal2nix "hnix-store-nar" "${inputs.hnix-store}/hnix-store-nar" { };
            hnix-store-readonly = super.callCabal2nix "hnix-store-readonly" "${inputs.hnix-store}/hnix-store-readonly" { };
            hnix-store-remote = super.callCabal2nix "hnix-store-remote" "${inputs.hnix-store}/hnix-store-remote" { };
            hnix-store-tests = super.callCabal2nix "hnix-store-tests" "${inputs.hnix-store}/hnix-store-tests" { };
            some = super.some_1_0_6;
          };
        };
      in
      hp.shellFor {
        packages = ps: [ ps.hnix ];
        nativeBuildInputs = with pkgs; with haskellPackages; [
          entr
          cabal-install
          haskell-language-server
        ];
      }
    );
  };
}
