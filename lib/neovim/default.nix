{nix-colors}: {
  pkgs,
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
  nix-colors-lib = nix-colors.lib.contrib {inherit pkgs;};
  tree-sitter = import ./tree-sitter-utils.nix {inherit pkgs;};

  inherit (autogroup-utils) makeAutogroups makeAutoCmds;
  inherit (keymap-utils) makeKeymap;
  inherit (lsp-utils) setupLsp lspPlugins;
  inherit (lua-utils) toLuaObject;
  inherit (nix-colors-lib) vimThemeFromScheme;
  inherit (plugin-utils) pack;
  inherit (tree-sitter) grammarsToPlugins makeTSConfig gtp;

  lspPackages = map (server: server.package) config.lsp.servers;

  finalPackages = with pkgs;
    [
      fd
      ripgrep
      fswatch
    ]
    ++ extraPackages
    ++ lspPackages;

  mkConfig = {
    colourscheme ? "chalk",
    plugins ? [],
    keymaps ? [],
    autogroups ? [],
    autocmds ? [],
    lsp ? {},
    globals ? {},
    opts ? {},
    treesitter ? {},
    ...
  }: let
    colourScheme = nix-colors.colorSchemes.${colourscheme};
    ts_grammars =
      []
      ++ (grammarsToPlugins treesitter.extra_grammars)
      ++ (map (g: {pkg = gtp g;}) pkgs.vimPlugins.nvim-treesitter.allGrammars);
    ts_plugins = [(makeTSConfig treesitter.config or {})] ++ ts_grammars;
    finalPlugins = plugins ++ [{pkg = vimThemeFromScheme {scheme = colourScheme;};}] ++ ts_plugins ++ lspPlugins;
  in
    pkgs.writeText "init.lua" (builtins.concatStringsSep "\n" [
      "vim.opt.packpath = '${pack finalPlugins}'"
      (makeAutogroups autogroups)
      (makeAutoCmds autocmds)
      (builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "vim.g['${name}'] = ${toLuaObject value}") globals))
      (builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "vim.opt.${name} = ${toLuaObject value}") opts))
      (setupLsp lsp)
      (makeKeymap keymaps)
      "vim.opt.runtimepath:remove(vim.fn.stdpath('config'))"
      "vim.opt.runtimepath:remove(vim.fn.stdpath('config'))"
      "vim.opt.runtimepath:remove(vim.fn.stdpath('data') .. '/site')"
      "vim.cmd[[colorscheme nix-${colourScheme.slug}]]"
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
    	--prefix PATH : ${pkgs.lib.makeBinPath finalPackages}
  ''
