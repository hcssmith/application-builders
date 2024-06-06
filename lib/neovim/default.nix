{pkgs, ...}: {
  neovim,
  extraPackages,
  config,
  ...
}: let
  autogroup-utils = import ./autogroup-utils.nix {inherit pkgs;};
  keymap-utils = import ./keymap-utils.nix {inherit pkgs;};
  lsp-utils = import ./lsp-utils.nix {inherit pkgs;};
  lua-utils = import ../utils/lua-utils.nix {inherit pkgs;};
  plugin-utils = import ./plugin-utils.nix {inherit pkgs;};

  inherit (autogroup-utils) makeAutogroups makeAutoCmds;
  inherit (keymap-utils) makeKeymap;
  inherit (lsp-utils) setupLsp;
  inherit (lua-utils) toLuaObject;
  inherit (plugin-utils) pack;

  mkConfig = {
    colourscheme ? "darkblue",
    plugins ? [],
    keymaps ? [],
    autogroups ? [],
    autocmds ? [],
    lsp ? {},
    globals ? {},
    opts ? {},
    ...
  }:
    pkgs.writeText "init.lua" (builtins.concatStringsSep "\n" [
      "vim.opt.packpath = '${pack plugins}'"
      (makeAutogroups autogroups)
      (makeAutoCmds autocmds)
      (builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "vim.g['${name}'] = ${toLuaObject value}") globals))
      (builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "vim.opt.${name} = ${toLuaObject value}") opts))
      (setupLsp lsp)
      (makeKeymap keymaps)
      "vim.opt.runtimepath:remove(vim.fn.stdpath('config'))"
      "vim.opt.runtimepath:remove(vim.fn.stdpath('config'))"
      "vim.opt.runtimepath:remove(vim.fn.stdpath('data') .. '/site')"
      "vim.cmd[[colorscheme ${colourscheme}]]"
    ]);
in
  pkgs.runCommand "${neovim.meta.mainProgram}" {
    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];
  } ''
    mkdir $out
    makeWrapper ${neovim}/bin/nvim $out/bin/nvim \
    	--add-flags "-u ${mkConfig config}" \
    	--prefix PATH : ${pkgs.lib.makeBinPath extraPackages}
  ''
