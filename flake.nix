{
  description = "Build npm and yarn packages";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      eachSystem = systems: f:
        let
          op = attrs: system:
            let
              ret = f system;
              op = attrs: key: attrs // { ${key} = (attrs.${key} or { }) // { ${system} = ret.${key}; }; };
            in
            builtins.foldl' op attrs (builtins.attrNames ret);
        in
        builtins.foldl' op { } systems;
    in
    {
      legacyPackages = eachSystem systems (system: nixpkgs.legacyPackages.${system}.callPackage ./default.nix { });
      overlays.default = final: prev: {
        inherit (final.callPackage ./. { }) mkNodeModules buildNpmPackage buildYarnPackage;
      };
      checks = eachSystem systems (system:
        let
          nixpkgs' = nixpkgs.legacyPackages.${system};
        in
        {
          npm6 = import ./tests/buildNpmPackage {
            pkgs = nixpkgs';
            npm-buildpackage = self.legacyPackages.${system}.override {
              nodejs = nixpkgs'.nodejs-14_x;
            };
          };
          npm8 = import ./tests/buildNpmPackage {
            pkgs = nixpkgs';
            npm-buildpackage = self.legacyPackages.${system}.override {
              nodejs = nixpkgs'.nodejs-18_x;
            };
          };
          yarn = import ./tests/buildYarnPackage {
            pkgs = nixpkgs.legacyPackages.${system};
            npm-buildpackage = self.legacyPackages.${system};
          };
        });
    };
}
