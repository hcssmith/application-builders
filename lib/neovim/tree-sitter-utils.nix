{pkgs, ...}: rec {
  makeTSConfig = config: {
    pkg = pkgs.vimPlugins.nvim-treesitter;
    name = "nvim-treesitter.configs";
    opts =
      config.opts
      or {
        highlight = {
          enable = true;
          disable = ["make"];
        };
        indent.enable = true;
      };
  };

  gtp = pkgs.vimPlugins.nvim-treesitter.grammarToPlugin;

  grammarsToPlugins = grammars: map (grammar: {pkg = (gtp grammar);}) (pkgs.lib.attrValues grammars);
}
