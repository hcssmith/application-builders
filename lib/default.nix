{
  nixpkgs,
  nix-colors,
  ...
}: {
  mkNeovim = import ./neovim {inherit nix-colors;};
  mkTmux = import ./tmux {inherit nix-colors;};
  mkNushell = import ./nushell {inherit nix-colors;};
  lua-utils = import ./utils/lua-utils.nix {pkgs = nixpkgs;};
}
