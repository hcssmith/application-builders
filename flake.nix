{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = {
    nixpkgs,
    nix-colors,
    ...
  }: {
    lib = import ./lib {inherit nixpkgs nix-colors;};
  };
}
