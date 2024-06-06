{pkgs, ...}: let
  lua-utils = import ../utils/lua-utils.nix {inherit pkgs;};
  keymap-utils = import ./keymap-utils.nix {inherit pkgs;};
  inherit (lua-utils) toLuaObject;
  inherit (keymap-utils) makeKeymaps;
in rec {
  packagePlugin = {
    pkg,
    optional ? false,
  } @ args: {
    name =
      if optional
      then "pack/${pkg.name}/opt/${pkg.name}"
      else "pack/${pkg.name}/start/${pkg.name}";
    path = pkgs.symLinkJoin {
      name = pkg.name;
      paths = [pkg (setupPlugin args)];
    };
  };

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
      pname = "${name}-setup";
      version = pkg.version;
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
        (makeKeymaps keymaps)
      ]);
      installPhase = ''
        mkdir -p $out
        cp $setup $out/plugin/${pname}-${version}.lua
      '';
    });

  pack = plugins:
    pkgs.linkFarm "neovim-plugins" (map (plugin: packagePlugin plugin) plugins);
}
