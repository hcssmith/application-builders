{nix-colors}: {
  pkgs,
  tmux ? pkgs.tmux,
  config,
  ...
}: let
  mkConfig = {
    prefix ? " ",
    colourscheme ? "katy",
    hsplit ? "|",
    vsplit ? "-",
    shell ? "nu",
    ...
  }: let
    colourScheme = nix-colors.colorSchemes.${colourscheme};

    base00 = colourScheme.palette.base00;
    base01 = colourScheme.palette.base01;
    base02 = colourScheme.palette.base02;
    base03 = colourScheme.palette.base03;
    base04 = colourScheme.palette.base04;
    base05 = colourScheme.palette.base05;
    base06 = colourScheme.palette.base06;
    base07 = colourScheme.palette.base07;
    base08 = colourScheme.palette.base08;
    base09 = colourScheme.palette.base09;
    base0A = colourScheme.palette.base0A;
    base0B = colourScheme.palette.base0B;
    base0C = colourScheme.palette.base0C;
    base0D = colourScheme.palette.base0D;
    base0E = colourScheme.palette.base0E;
    base0F = colourScheme.palette.base0F;

    theme = ''
         set -g pane-border-style 'fg=#${base00}'
         set -g pane-active-border-style 'fg=#${base01}'
         set -g status-position top
         set -g status-justify absolute-centre
         set -g status-style 'bg=default fg=#${base05}'
      set -g message-style 'bg=default'
         set -g status-right ' '
         set -g status-left ' '
         set -g status-right-length 50
         set -g status-left-length 10
         setw -g window-status-current-style 'fg=#${base01} bg=#${base05}'
         setw -g window-status-current-format ' #I #W #F '

         setw -g window-status-style 'fg=#${base05} dim'
         setw -g window-status-format ' #I #[fg=#${base07}]#W #[fg=#${base00}]#F '

         # Start windows and panes index at 1, not 0.
         set -g base-index 1
         setw -g pane-base-index 1

         # Ensure window index numbers get reordered on delete.
         set-option -g renumber-windows on
    '';

    normalise = p:
      if p == " "
      then "Space"
      else p;
    setPrefix = prefix:
      builtins.concatStringsSep "\n" [
        "set-option -g prefix C-${normalise prefix}"
        "bind-key C-${normalise prefix} send-prefix"
      ];
    nvimIntegration = ''
      # See: https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
      		| grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      bind-key -n 'C-left' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-down' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-up' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-right' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
      		"bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
      		"bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l
      bind-key -T copy-mode-vi 'C-left' select-pane -L
      bind-key -T copy-mode-vi 'C-down' select-pane -D
      bind-key -T copy-mode-vi 'C-up' select-pane -U
      bind-key -T copy-mode-vi 'C-right' select-pane -R
    '';
  in
    pkgs.writeText "tmux.conf" (builtins.concatStringsSep "\n" (pkgs.lib.flatten [
      "unbind C-b"
      (setPrefix prefix)
      "unbind %"
      "unbind '\"'"
      "bind ${hsplit} split-window -h"
      "bind ${vsplit} split-window -v"
      "bind -n C-t new-window"
      "bind -n C-w kill-window"
      (map (id: "bind-key -n M-${builtins.toString id} select-window -t ${builtins.toString id}") (pkgs.lib.range 1 9))
      "set -g mouse on"
      nvimIntegration
      theme
      "set -g default-command 'exec ${shell}'"
    ]));
in
  pkgs.runCommand tmux.meta.mainProgram {
    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];
  } ''
    mkdir $out
    makeWrapper ${tmux}/bin/tmux $out/bin/tmux \
    	--add-flags "-f ${mkConfig config}"
  ''
