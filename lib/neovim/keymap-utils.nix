{pkgs, ...}: let
  lua-utils = import ../utils/lua-utils.nix {inherit pkgs;};

  toLuaObject = lua-utils.toLuaObject;
in {
  makeKeymap = keymaps:
    builtins.concatStringsSep "\n" (map ({
      action,
      key,
      opts ? {},
      mode ? ["n"],
      lua ? true,
    }:
      if lua
      then "vim.keymap.set(${toLuaObject mode}, '${key}', ${action}, ${toLuaObject opts})"
      else "vim.keymap.set(${toLuaObject mode}, '${key}', [[${action}]], ${toLuaObject opts})")
    keymaps);
}
