{nix-colors}: {
  pkgs,
  wezterm ? pkgs.wezterm,
  shell ? "nu",
  config,
  ...
}: let
  lua-utils = import ../utils/lua-utils.nix {inherit pkgs;};
  inherit (lua-utils) toLuaObject;

  mkConfig = {tabBar ? false}:
    pkgs.writeText "wezterm.lua" (builtins.concatStringsSep "\n" [
      "local wezterm = require('wezterm')"
      "local config = wezterm.config_builder()"
      "config.enable_tab_bar = ${toLuaObject tabBar}"
      "config.font = wezterm.font_with_fallback {"
      "'CMU Typewriter Text',"
      "'FiraCode Mono',"
      "}"
      "config.default_prog = {'${shell}'}"
      "config.front_end=\"WebGpu\""
      "config.window_background_opacity = 0.7"
      "return config"
    ]);
in
  pkgs.runCommand wezterm.meta.mainProgram {
    nativeBuildInputs = with pkgs; [makeWrapper];
  } ''
    mkdir -p $out/bin
     makeWrapper ${wezterm}/bin/wezterm $out/bin/wezterm \
    	--add-flags "--config-file ${mkConfig config}"
  ''
