{nix-colors}: {
  pkgs,
  nushell ? pkgs.nushell,
  config ? {},
  env ? {},
  keybindings ? [],
  includes ? [],
  extraPackages ? [],
  ...
}: let
  buildConfig = {
    config ? {},
    keybindings ? [],
    ...
  }: let
    genYAML = pkgs.lib.generators.toYAML {};
  in
    genYAML ({
        inherit keybindings;
      }
      // config);

  finalPackages = extraPackages;

  mkConfigFile = config:
    pkgs.writeText "nu.conf" (
      builtins.concatStringsSep "\n" (pkgs.lib.flatten [
        "$env.config = ${buildConfig config}"
        (map (file: builtins.readFile file) includes)
        (pkgs.lib.mapAttrsToList (name: value: "$env.${name} = '${value}'") env)
      ])
    );
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
    --add-flags "--config ${mkConfigFile {inherit config keybindings;}}" \
    --prefix PATH : ${pkgs.lib.makeBinPath finalPackages}
  ''
