{nix-xolors}: {
	pkgs,
	config,
	...
}: pkgs.writeShellScriptBin "test" ''
	echo test
'';
