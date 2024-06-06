{
  nixpkgs,
  nix-colors,
  ...
}: {
  mkNeovim = import ./neovim {
    inherit nix-colors;
  };
  utils = import ./utils {inherit nixpkgs;};
}
