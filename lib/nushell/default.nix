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
    ];

  finalPackages =
    extraPackages
    ++ [
      pkgs.fh
    ];

  srcFunctions = builtins.readFile ./src_functions.nu;
  appFunctions = builtins.readFile ./app_functions.nu;

  mkConfig = config:
    pkgs.writeText "nu.conf" (builtins.concatStringsSep "\n" [
      "$env.config = {"
      (configOptions config)
      "}"
      srcFunctions
      appFunctions
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
