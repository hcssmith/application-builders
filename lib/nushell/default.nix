{nix-colors}: {
  pkgs,
  nushell ? pkgs.nushell,
  config,
  extraPackages,
  ...
}: let
  configOptions = {showBanner ? false, ...}:
    builtins.concatStringsSep "\n" [
      "show_banner: ${
        if showBanner
        then "true"
        else "false"
      }"
      "keybindings: ["
      "{"
      "name: select_project"
      "modifier: control"
      "keycode: char_p"
      "mode: emacs"
      "event: {"
      "send: executehostcommand,"
      "cmd: \"ls /home/hcssmith/Projects -s | where type == 'dir' | get name | to text | fzf --height 60% --layout reverse --border --tmux | cd $'/home/hcssmith/Projects/($in)'\""
      "}"
      "}"
      "]"
    ];

  finalPackages =
    extraPackages
    ++ [
      pkgs.fh
    ];

  srcFunctions = builtins.readFile ./src_functions.nu;
  appFunctions = builtins.readFile ./app_functions.nu;
  moveFunctions = builtins.readFile ./move_functions.nu;

  mkConfig = config:
    pkgs.writeText "nu.conf" (builtins.concatStringsSep "\n" [
      "$env.config = {"
      (configOptions config)
      "}"
      srcFunctions
      appFunctions
      moveFunctions
    ]);
in
  pkgs.runCommand nushell.meta.mainProgram
  {
    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];
  }
  ''
     mkdir -p $out/bin
     makeWrapper ${nushell}/bin/nu $out/bin/nu \
    --add-flags "--config ${mkConfig config}" \
    --prefix PATH : ${pkgs.lib.makeBinPath finalPackages}
  ''
