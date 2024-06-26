{pkgs, ...}: let
  lua-utils = import ../utils/lua-utils.nix {inherit pkgs;};
  inherit (lua-utils) toLuaObject;
  lib = pkgs.lib;
in rec {
  _on_attach = {
    __raw = ''
      function(client, bufnr)
      require("lsp_signature").on_attach({
      bind = true,
      handler_opts = {
      border = "rounded",
      },
      }, bufnr)
      end
    '';
  };

  _capabilities = {
    __raw = "vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), require('cmp_nvim_lsp').default_capabilities())";
  };

  mkServerConfig = {
    server_name,
    cmd ? null,
    settings ? {},
    on_attach ? null,
    capabilities ? null,
    ...
  }: rec {
    name = server_name;
    on_attach_func =
      if (on_attach == null)
      then _on_attach
      else on_attach;
    capabilities_func =
      if capabilities == null
      then _capabilities
      else capabilities;
    srv_config =
      let 
				_cmd = if (builtins.isNull cmd) then {} else {cmd = cmd;};  
			in toLuaObject {
        name = name;
        extraOptions =
          {
            settings.${name} = settings;
          }
          // {
            on_attach = on_attach_func;
            capabilities = capabilities_func;
          } // _cmd;
      }
      + ",";
  };

  setupLsp = {servers ? [], ...}: (
    builtins.concatStringsSep "\n" (lib.flatten [
      "local __LspServers = {"
      (map (srv: let s = mkServerConfig srv; in s.srv_config) servers)
      "}"
      ''
        for i, s in ipairs(__LspServers) do
        require('lspconfig')[s.name].setup(s.extraOptions)
        end

      ''
    ])
  );

  lspPlugins = with pkgs.vimPlugins; [
    {pkg = none-ls-nvim;}
    {pkg = nvim-lspconfig;}
    {
      pkg = lspsaga-nvim;
      name = "lspsaga";
      opts = {
        symbol_in_winbar.enable = false;
      };
    }
    {pkg = lsp_signature-nvim;}
    {pkg = lspkind-nvim;}
  ];
}
