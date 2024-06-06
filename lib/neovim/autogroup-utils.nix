{pkgs, ...}: let
  lua-utils = import ../utils/lua-utils.nix {inherit pkgs;};
  inherit (lua-utils) toLuaObject;
in {
  makeAutogroups = autogroups: builtins.concatStringsSep "\n" (map (ag: "vim.api.nvim_create_augroup('${ag}', {clear = false})") autogroups);
  makeAutoCmds = autocmds:
    builtins.concatStringsSep "\n" (map (
        {
          event,
          desc,
          group,
          callback,
          pattern ? null,
        }:
          builtins.concatStringsSep "\n" [
            "vim.api.nvim_create_autocmd(${toLuaObject event}, {"
            (
              if (pattern == null)
              then ""
              else "pattern = ${toLuaObject pattern},"
            )
            "desc = '${desc}',"
            "group = '${group}',"
            "callback = ${toLuaObject callback}"
            "})"
          ]
      )
      autocmds);
}
