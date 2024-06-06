{pkgs, ...}: let
  lua-utils = import ../utils/lua-utils.nix {inherit pkgs;};
  keymap-utils = import ./keymap-utils.nix {inherit pkgs;};
  inherit (lua-utils) toLuaObject;
  inherit (keymap-utils) makeKeymap;
in rec {
  packagePlugin = {
    pkg,
    optional ? false,
    ...
  } @ args: {
    name =
      if optional
      then "pack/${pkg.name}/opt/${pkg.name}"
      else "pack/${pkg.name}/start/${pkg.name}";
    path = pkgs.symlinkJoin {
      name = pkg.name;
      paths = pkgs.lib.flatten [
        pkg
        (
          if (setupRequired args)
          then (setupPlugin args)
          else []
        )
      ];
    };
  };

  setupRequired = {
    name ? "",
    extraConfigPre ? "",
    extraConfig ? "",
    extraConfigVim ? "",
    keymaps ? [],
    ...
  }:
    if (name != "" || extraConfigPre != "" || extraConfig != "" || extraConfigVim != "" || (builtins.length keymaps) > 0)
    then true
    else false;

  setupPlugin = {
    pkg,
    name ? "",
    opts ? {},
    extraConfigPre ? "",
    extraConfig ? "",
    extraConfigVim ? "",
    keymaps ? [],
    ...
  }:
    pkgs.stdenv.mkDerivation (finalAttrs: rec {
      pname = "${pkg.name}-setup";
      version = "${pkg.version}";
      dontUnpack = true;
      buildPhases = ["installPhase"];
      setup = pkgs.writeText "${pname}-${version}" (builtins.concatStringsSep "\n" [
        extraConfigPre
        (
          if (name != "")
          then "require('${name}').setup(${toLuaObject opts})"
          else ""
        )
        extraConfig
        (builtins.concatStringsSep "\n" [
          "vim.cmd [["
          extraConfigVim
          "]]"
        ])
        (makeKeymap keymaps)
      ]);
      installPhase = ''
        mkdir -p $out/plugin
        cp $setup $out/plugin/${pname}-${version}.lua
      '';
    });

  pack = plugins:
    pkgs.linkFarm "neovim-plugins" ((map (plugin: packagePlugin plugin) plugins)
      ++ (map (plugin: packagePlugin plugin) (builtins.concatMap ({deps ? [], ...}: deps) plugins)));
}
